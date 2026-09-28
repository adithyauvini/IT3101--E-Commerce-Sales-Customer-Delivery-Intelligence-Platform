/* =========================================================
   FILE: 04_dimensions.sql
   PURPOSE:
   Create and populate the Dimension Tables
   ========================================================= */


USE OlistDWBI;
GO


/* =========================================================
   1. DIM DATE
   ========================================================= */

IF OBJECT_ID('dw.DimDate', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimDate
    (
        DateKey INT NOT NULL PRIMARY KEY,
        FullDate DATE NOT NULL,
        [Year] INT NOT NULL,
        [Quarter] INT NOT NULL,
        [Month] INT NOT NULL,
        MonthName VARCHAR(20) NOT NULL,
        [Week] INT NOT NULL,
        [Day] INT NOT NULL,
        DayName VARCHAR(20) NOT NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate DimDate
   --------------------------------------------------------- */

;WITH DateRange AS
(
    SELECT
        CAST(MIN(CAST(order_purchase_timestamp AS DATE)) AS DATE) AS StartDate,
        CAST(MAX(CAST(order_purchase_timestamp AS DATE)) AS DATE) AS EndDate
    FROM stg.olist_orders
),
DateList AS
(
    SELECT StartDate AS FullDate, EndDate
    FROM DateRange

    UNION ALL

    SELECT
        DATEADD(DAY, 1, FullDate),
        EndDate
    FROM DateList
    WHERE FullDate < EndDate
)
INSERT INTO dw.DimDate
(
    DateKey,
    FullDate,
    [Year],
    [Quarter],
    [Month],
    MonthName,
    [Week],
    [Day],
    DayName
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)) AS DateKey,
    FullDate,
    YEAR(FullDate) AS [Year],
    DATEPART(QUARTER, FullDate) AS [Quarter],
    MONTH(FullDate) AS [Month],
    DATENAME(MONTH, FullDate) AS MonthName,
    DATEPART(WEEK, FullDate) AS [Week],
    DAY(FullDate) AS [Day],
    DATENAME(WEEKDAY, FullDate) AS DayName
FROM DateList
OPTION (MAXRECURSION 0);
GO


/* =========================================================
   2. DIM CUSTOMER
   ========================================================= */

IF OBJECT_ID('dw.DimCustomer', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimCustomer
    (
        CustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CustomerID VARCHAR(50) NOT NULL,
        CustomerUniqueID VARCHAR(50) NOT NULL,
        CustomerZipCodePrefix INT NULL,
        CustomerCity VARCHAR(100) NULL,
        CustomerState VARCHAR(10) NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate DimCustomer
   --------------------------------------------------------- */

INSERT INTO dw.DimCustomer
(
    CustomerID,
    CustomerUniqueID,
    CustomerZipCodePrefix,
    CustomerCity,
    CustomerState
)
SELECT
    CustomerID,
    CustomerUniqueID,
    CustomerZipCodePrefix,
    CustomerCity,
    CustomerState
FROM stg.olist_customers;
GO


/* =========================================================
   3. DIM PRODUCT
   ========================================================= */

IF OBJECT_ID('dw.DimProduct', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimProduct
    (
        ProductKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ProductID VARCHAR(50) NOT NULL,
        ProductCategoryName VARCHAR(100) NULL,
        ProductCategoryEnglish VARCHAR(100) NULL,
        ProductNameLength INT NULL,
        ProductDescriptionLength INT NULL,
        ProductPhotosQty INT NULL,
        ProductWeightG DECIMAL(18,2) NULL,
        ProductLengthCM DECIMAL(18,2) NULL,
        ProductHeightCM DECIMAL(18,2) NULL,
        ProductWidthCM DECIMAL(18,2) NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate DimProduct
   --------------------------------------------------------- */

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
    p.product_category_name,
    t.product_category_name_english,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM stg.olist_products p
LEFT JOIN stg.product_category_translation t
    ON p.product_category_name = t.product_category_name;
GO


/* =========================================================
   4. DIM SELLER
   ========================================================= */

IF OBJECT_ID('dw.DimSeller', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimSeller
    (
        SellerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SellerID VARCHAR(50) NOT NULL,
        SellerZipCodePrefix INT NULL,
        SellerCity VARCHAR(100) NULL,
        SellerState VARCHAR(10) NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate DimSeller
   --------------------------------------------------------- */

INSERT INTO dw.DimSeller
(
    SellerID,
    SellerZipCodePrefix,
    SellerCity,
    SellerState
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM stg.olist_sellers;
GO


/* =========================================================
   5. DIM LOCATION
   ========================================================= */

IF OBJECT_ID('dw.DimLocation', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimLocation
    (
        LocationKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ZipCodePrefix INT NOT NULL,
        City VARCHAR(100) NULL,
        State VARCHAR(10) NULL,
        Latitude DECIMAL(10,8) NULL,
        Longitude DECIMAL(11,8) NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate DimLocation
   --------------------------------------------------------- */

INSERT INTO dw.DimLocation
(
    ZipCodePrefix,
    City,
    State,
    Latitude,
    Longitude
)
SELECT
    geolocation_zip_code_prefix,
    MAX(geolocation_city) AS City,
    MAX(geolocation_state) AS State,
    AVG(geolocation_lat) AS Latitude,
    AVG(geolocation_lng) AS Longitude
FROM stg.olist_geolocation
GROUP BY
    geolocation_zip_code_prefix;
GO


/* =========================================================
   6. DIM PAYMENT TYPE
   ========================================================= */

IF OBJECT_ID('dw.DimPaymentType', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimPaymentType
    (
        PaymentTypeKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PaymentType VARCHAR(50) NOT NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate DimPaymentType
   --------------------------------------------------------- */

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
   7. VERIFY DIMENSION ROW COUNTS
   ========================================================= */

SELECT
    'dw.DimDate' AS TableName,
    COUNT(*) AS TotalRows
FROM dw.DimDate

UNION ALL

SELECT
    'dw.DimCustomer',
    COUNT(*)
FROM dw.DimCustomer

UNION ALL

SELECT
    'dw.DimProduct',
    COUNT(*)
FROM dw.DimProduct

UNION ALL

SELECT
    'dw.DimSeller',
    COUNT(*)
FROM dw.DimSeller

UNION ALL

SELECT
    'dw.DimLocation',
    COUNT(*)
FROM dw.DimLocation

UNION ALL

SELECT
    'dw.DimPaymentType',
    COUNT(*)
FROM dw.DimPaymentType

ORDER BY TableName;
GO