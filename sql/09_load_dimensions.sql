/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
09_load_dimensions.sql

Purpose:
Loads all dimension tables from the validated staging layer.

Dimensions:
    dw.DimDate
    dw.DimLocation
    dw.DimCustomer
    dw.DimProduct
    dw.DimSeller
    dw.DimPaymentType

Design decisions:
- Surrogate key 0 is reserved for Unknown members.
- DimDate covers purchase, delivery, and estimated dates.
- DimLocation contains ZIP prefixes from geolocation,
  customers, and sellers.
- Missing English category translations fall back to the
  original Portuguese category.
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. RESET DIMENSION TABLES

   DimCustomer and DimSeller reference DimLocation,
   so they must be cleared first.
   ========================================================= */

DELETE FROM dw.DimCustomer;
DELETE FROM dw.DimSeller;

DELETE FROM dw.DimProduct;
DELETE FROM dw.DimPaymentType;
DELETE FROM dw.DimDate;

DELETE FROM dw.DimLocation;
GO


/* =========================================================
   2. RESET IDENTITY VALUES
   ========================================================= */

DBCC CHECKIDENT ('dw.DimLocation', RESEED, 0);
DBCC CHECKIDENT ('dw.DimCustomer', RESEED, 0);
DBCC CHECKIDENT ('dw.DimProduct', RESEED, 0);
DBCC CHECKIDENT ('dw.DimSeller', RESEED, 0);
DBCC CHECKIDENT ('dw.DimPaymentType', RESEED, 0);
GO


/* =========================================================
   3. LOAD DIM DATE

   The required range is calculated dynamically from:

   - Purchase date
   - Actual customer delivery date
   - Estimated delivery date

   Expected range from our audit:
   2016-09-04 to 2018-11-12
   ========================================================= */

;WITH DateBounds AS
(
    SELECT
        MIN(DateValue) AS MinDate,
        MAX(DateValue) AS MaxDate
    FROM
    (
        SELECT
            CAST(order_purchase_timestamp AS DATE)
                AS DateValue
        FROM stg.olist_orders
        WHERE order_purchase_timestamp IS NOT NULL

        UNION ALL

        SELECT
            CAST(order_delivered_customer_date AS DATE)
        FROM stg.olist_orders
        WHERE order_delivered_customer_date IS NOT NULL

        UNION ALL

        SELECT
            CAST(order_estimated_delivery_date AS DATE)
        FROM stg.olist_orders
        WHERE order_estimated_delivery_date IS NOT NULL

    ) AS SourceDates
),

DateSeries AS
(
    SELECT
        MinDate AS FullDate
    FROM DateBounds

    UNION ALL

    SELECT
        DATEADD(DAY, 1, ds.FullDate)

    FROM DateSeries AS ds

    CROSS JOIN DateBounds AS db

    WHERE ds.FullDate < db.MaxDate
)

INSERT INTO dw.DimDate
(
    DateKey,
    FullDate,
    DayOfMonth,
    DayName,
    MonthNumber,
    MonthName,
    QuarterNumber,
    QuarterName,
    YearNumber,
    YearMonthKey,
    YearMonthLabel
)

SELECT
    YEAR(FullDate) * 10000
        + MONTH(FullDate) * 100
        + DAY(FullDate)
        AS DateKey,

    FullDate,

    DAY(FullDate)
        AS DayOfMonth,

    DATENAME(WEEKDAY, FullDate)
        AS DayName,

    MONTH(FullDate)
        AS MonthNumber,

    DATENAME(MONTH, FullDate)
        AS MonthName,

    DATEPART(QUARTER, FullDate)
        AS QuarterNumber,

    CONCAT(
        'Q',
        DATEPART(QUARTER, FullDate)
    )
        AS QuarterName,

    YEAR(FullDate)
        AS YearNumber,

    YEAR(FullDate) * 100
        + MONTH(FullDate)
        AS YearMonthKey,

    CONCAT(
        YEAR(FullDate),
        '-',
        RIGHT(
            '0' + CAST(MONTH(FullDate) AS VARCHAR(2)),
            2
        )
    )
        AS YearMonthLabel

FROM DateSeries

OPTION (MAXRECURSION 0);
GO


/* =========================================================
   4. CREATE UNKNOWN LOCATION

   LocationKey 0 is reserved as the technical fallback.
   ========================================================= */

SET IDENTITY_INSERT dw.DimLocation ON;
GO

INSERT INTO dw.DimLocation
(
    LocationKey,
    ZipCodePrefix,
    City,
    State,
    Latitude,
    Longitude,
    HasGeolocation
)
VALUES
(
    0,
    -1,
    'Unknown',
    'NA',
    NULL,
    NULL,
    0
);
GO

SET IDENTITY_INSERT dw.DimLocation OFF;
GO


/* =========================================================
   5. LOAD DIM LOCATION

   Every ZIP prefix required by geolocation, customers,
   or sellers is included.

   Geolocation latitude/longitude is averaged by ZIP.

   Where a ZIP has multiple city/state labels, the most
   frequently occurring combination is selected.
   ========================================================= */

;WITH AllZipPrefixes AS
(
    SELECT
        geolocation_zip_code_prefix AS ZipCodePrefix
    FROM stg.olist_geolocation
    WHERE geolocation_zip_code_prefix IS NOT NULL

    UNION

    SELECT
        customer_zip_code_prefix
    FROM stg.olist_customers
    WHERE customer_zip_code_prefix IS NOT NULL

    UNION

    SELECT
        seller_zip_code_prefix
    FROM stg.olist_sellers
    WHERE seller_zip_code_prefix IS NOT NULL
),

GeoCoordinates AS
(
    SELECT
        geolocation_zip_code_prefix AS ZipCodePrefix,

        CAST(
            AVG(
                CAST(
                    geolocation_lat
                    AS DECIMAL(18,8)
                )
            )
            AS DECIMAL(12,8)
        ) AS Latitude,

        CAST(
            AVG(
                CAST(
                    geolocation_lng
                    AS DECIMAL(18,8)
                )
            )
            AS DECIMAL(12,8)
        ) AS Longitude

    FROM stg.olist_geolocation

    WHERE geolocation_zip_code_prefix IS NOT NULL

    GROUP BY
        geolocation_zip_code_prefix
),

GeoNameCounts AS
(
    SELECT
        geolocation_zip_code_prefix AS ZipCodePrefix,
        geolocation_city AS City,
        geolocation_state AS State,
        COUNT(*) AS OccurrenceCount

    FROM stg.olist_geolocation

    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
),

GeoNames AS
(
    SELECT
        ZipCodePrefix,
        City,
        State,

        ROW_NUMBER() OVER
        (
            PARTITION BY ZipCodePrefix

            ORDER BY
                OccurrenceCount DESC,
                City,
                State
        ) AS RowNumber

    FROM GeoNameCounts
),

CustomerNameCounts AS
(
    SELECT
        customer_zip_code_prefix AS ZipCodePrefix,
        customer_city AS City,
        customer_state AS State,
        COUNT(*) AS OccurrenceCount

    FROM stg.olist_customers

    WHERE customer_zip_code_prefix IS NOT NULL

    GROUP BY
        customer_zip_code_prefix,
        customer_city,
        customer_state
),

CustomerNames AS
(
    SELECT
        ZipCodePrefix,
        City,
        State,

        ROW_NUMBER() OVER
        (
            PARTITION BY ZipCodePrefix

            ORDER BY
                OccurrenceCount DESC,
                City,
                State
        ) AS RowNumber

    FROM CustomerNameCounts
),

SellerNameCounts AS
(
    SELECT
        seller_zip_code_prefix AS ZipCodePrefix,
        seller_city AS City,
        seller_state AS State,
        COUNT(*) AS OccurrenceCount

    FROM stg.olist_sellers

    WHERE seller_zip_code_prefix IS NOT NULL

    GROUP BY
        seller_zip_code_prefix,
        seller_city,
        seller_state
),

SellerNames AS
(
    SELECT
        ZipCodePrefix,
        City,
        State,

        ROW_NUMBER() OVER
        (
            PARTITION BY ZipCodePrefix

            ORDER BY
                OccurrenceCount DESC,
                City,
                State
        ) AS RowNumber

    FROM SellerNameCounts
)

INSERT INTO dw.DimLocation
(
    ZipCodePrefix,
    City,
    State,
    Latitude,
    Longitude,
    HasGeolocation
)

SELECT
    z.ZipCodePrefix,

    COALESCE(
        gn.City,
        cn.City,
        sn.City,
        'Unknown'
    ) AS City,

    COALESCE(
        gn.State,
        cn.State,
        sn.State,
        'NA'
    ) AS State,

    gc.Latitude,

    gc.Longitude,

    CASE
        WHEN gc.ZipCodePrefix IS NULL
            THEN 0
        ELSE 1
    END AS HasGeolocation

FROM AllZipPrefixes AS z

LEFT JOIN GeoCoordinates AS gc
    ON z.ZipCodePrefix = gc.ZipCodePrefix

LEFT JOIN GeoNames AS gn
    ON z.ZipCodePrefix = gn.ZipCodePrefix
    AND gn.RowNumber = 1

LEFT JOIN CustomerNames AS cn
    ON z.ZipCodePrefix = cn.ZipCodePrefix
    AND cn.RowNumber = 1

LEFT JOIN SellerNames AS sn
    ON z.ZipCodePrefix = sn.ZipCodePrefix
    AND sn.RowNumber = 1;
GO


/* =========================================================
   6. CREATE UNKNOWN CUSTOMER

   CustomerKey = 0 is reserved as fallback.
   ========================================================= */

SET IDENTITY_INSERT dw.DimCustomer ON;
GO

INSERT INTO dw.DimCustomer
(
    CustomerKey,
    CustomerID,
    CustomerUniqueID,
    LocationKey
)
VALUES
(
    0,
    'UNKNOWN',
    'UNKNOWN',
    0
);
GO

SET IDENTITY_INSERT dw.DimCustomer OFF;
GO


/* =========================================================
   7. LOAD DIM CUSTOMER

   Grain:
   One row per source customer_id.

   customer_unique_id allows repeat customers to be
   identified across different customer_id values.
   ========================================================= */

INSERT INTO dw.DimCustomer
(
    CustomerID,
    CustomerUniqueID,
    LocationKey
)

SELECT
    c.customer_id,

    c.customer_unique_id,

    COALESCE(
        l.LocationKey,
        0
    ) AS LocationKey

FROM stg.olist_customers AS c

LEFT JOIN dw.DimLocation AS l
    ON c.customer_zip_code_prefix =
       l.ZipCodePrefix;
GO


/* =========================================================
   8. CREATE UNKNOWN PRODUCT

   ProductKey = 0 is reserved as fallback.
   ========================================================= */

SET IDENTITY_INSERT dw.DimProduct ON;
GO

INSERT INTO dw.DimProduct
(
    ProductKey,
    ProductID,
    ProductCategoryName,
    ProductCategoryEnglish,
    ProductNameLength,
    ProductDescriptionLength,
    ProductPhotosQty,
    ProductWeightG,
    ProductLengthCM,
    ProductHeightCM,
    ProductWidthCM
)
VALUES
(
    0,
    'UNKNOWN',
    'Unknown',
    'Unknown',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
);
GO

SET IDENTITY_INSERT dw.DimProduct OFF;
GO


/* =========================================================
   9. LOAD DIM PRODUCT

   Category translation rules:

   1. English translation when available.
   2. Portuguese category if translation is unavailable.
   3. 'Unknown' when the source category is NULL.

   This preserves:
   pc_gamer
   portateis_cozinha_e_preparadores_de_alimentos

   even though they are missing from the translation file.
   ========================================================= */

INSERT INTO dw.DimProduct
(
    ProductID,
    ProductCategoryName,
    ProductCategoryEnglish,
    ProductNameLength,
    ProductDescriptionLength,
    ProductPhotosQty,
    ProductWeightG,
    ProductLengthCM,
    ProductHeightCM,
    ProductWidthCM
)

SELECT
    p.product_id,

    COALESCE(
        p.product_category_name,
        'Unknown'
    ) AS ProductCategoryName,

    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS ProductCategoryEnglish,

    p.product_name_lenght,

    p.product_description_lenght,

    p.product_photos_qty,

    p.product_weight_g,

    p.product_length_cm,

    p.product_height_cm,

    p.product_width_cm

FROM stg.olist_products AS p

LEFT JOIN stg.product_category_name_translation AS t
    ON p.product_category_name =
       t.product_category_name;
GO


/* =========================================================
   10. CREATE UNKNOWN SELLER

   SellerKey = 0 is reserved as fallback.
   ========================================================= */

SET IDENTITY_INSERT dw.DimSeller ON;
GO

INSERT INTO dw.DimSeller
(
    SellerKey,
    SellerID,
    LocationKey
)
VALUES
(
    0,
    'UNKNOWN',
    0
);
GO

SET IDENTITY_INSERT dw.DimSeller OFF;
GO


/* =========================================================
   11. LOAD DIM SELLER

   Grain:
   One row per seller_id.
   ========================================================= */

INSERT INTO dw.DimSeller
(
    SellerID,
    LocationKey
)

SELECT
    s.seller_id,

    COALESCE(
        l.LocationKey,
        0
    ) AS LocationKey

FROM stg.olist_sellers AS s

LEFT JOIN dw.DimLocation AS l
    ON s.seller_zip_code_prefix =
       l.ZipCodePrefix;
GO


/* =========================================================
   12. CREATE UNKNOWN PAYMENT TYPE

   PaymentTypeKey = 0 is technical fallback.

   IMPORTANT:
   'unknown' and 'not_defined' are different.

   unknown:
       warehouse technical fallback

   not_defined:
       actual value present in the Olist source
   ========================================================= */

SET IDENTITY_INSERT dw.DimPaymentType ON;
GO

INSERT INTO dw.DimPaymentType
(
    PaymentTypeKey,
    PaymentType
)
VALUES
(
    0,
    'unknown'
);
GO

SET IDENTITY_INSERT dw.DimPaymentType OFF;
GO


/* =========================================================
   13. LOAD DIM PAYMENT TYPE

   Source values expected:
       credit_card
       boleto
       voucher
       debit_card
       not_defined
   ========================================================= */

INSERT INTO dw.DimPaymentType
(
    PaymentType
)

SELECT DISTINCT
    payment_type

FROM stg.olist_order_payments

WHERE payment_type IS NOT NULL;
GO


/* =========================================================
   14. VERIFY DIMENSION ROW COUNTS
   ========================================================= */

SELECT
    'DimDate' AS DimensionName,
    COUNT(*) AS TotalRows
FROM dw.DimDate

UNION ALL

SELECT
    'DimLocation',
    COUNT(*)
FROM dw.DimLocation

UNION ALL

SELECT
    'DimCustomer',
    COUNT(*)
FROM dw.DimCustomer

UNION ALL

SELECT
    'DimProduct',
    COUNT(*)
FROM dw.DimProduct

UNION ALL

SELECT
    'DimSeller',
    COUNT(*)
FROM dw.DimSeller

UNION ALL

SELECT
    'DimPaymentType',
    COUNT(*)
FROM dw.DimPaymentType;
GO


/* =========================================================
   15. VERIFY DATE RANGE
   ========================================================= */

SELECT
    COUNT(*) AS DateRows,

    MIN(FullDate) AS MinimumDate,

    MAX(FullDate) AS MaximumDate

FROM dw.DimDate;
GO


/* =========================================================
   16. VERIFY BUSINESS CUSTOMERS USING UNKNOWN LOCATION

   CustomerKey 0 is excluded because that is the deliberate
   technical Unknown customer.
   ========================================================= */

SELECT
    COUNT(*) AS CustomersUsingUnknownLocation

FROM dw.DimCustomer

WHERE LocationKey = 0
  AND CustomerKey <> 0;
GO


/* =========================================================
   17. VERIFY BUSINESS SELLERS USING UNKNOWN LOCATION

   SellerKey 0 is excluded because it is the technical
   Unknown seller.
   ========================================================= */

SELECT
    COUNT(*) AS SellersUsingUnknownLocation

FROM dw.DimSeller

WHERE LocationKey = 0
  AND SellerKey <> 0;
GO


/* =========================================================
   18. VERIFY GEOLOCATION COVERAGE
   ========================================================= */

SELECT
    HasGeolocation,

    COUNT(*) AS LocationRows

FROM dw.DimLocation

GROUP BY HasGeolocation

ORDER BY HasGeolocation DESC;
GO


/* =========================================================
   19. VERIFY PAYMENT TYPES
   ========================================================= */

SELECT
    PaymentTypeKey,
    PaymentType

FROM dw.DimPaymentType

ORDER BY PaymentTypeKey;
GO


/* =========================================================
   20. VERIFY PRODUCT CATEGORY FALLBACK

   ProductKey 0 is excluded because it is the technical
   Unknown product.

   Expected:
   610 real products with missing source category.
   ========================================================= */

SELECT
    COUNT(*) AS UnknownProductCategories

FROM dw.DimProduct

WHERE ProductCategoryEnglish = 'Unknown'
  AND ProductKey <> 0;
GO


/* =========================================================
   21. VERIFY UNKNOWN MEMBERS
   ========================================================= */

SELECT
    CustomerKey,
    CustomerID,
    CustomerUniqueID,
    LocationKey

FROM dw.DimCustomer

WHERE CustomerKey = 0;
GO


SELECT
    ProductKey,
    ProductID,
    ProductCategoryEnglish

FROM dw.DimProduct

WHERE ProductKey = 0;
GO


SELECT
    SellerKey,
    SellerID,
    LocationKey

FROM dw.DimSeller

WHERE SellerKey = 0;
GO


SELECT
    PaymentTypeKey,
    PaymentType

FROM dw.DimPaymentType

WHERE PaymentTypeKey = 0;
GO