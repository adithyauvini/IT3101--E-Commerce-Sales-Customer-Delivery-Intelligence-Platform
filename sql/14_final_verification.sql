/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
14_final_verification.sql

Purpose:
Performs final verification of the complete DWBI database
before Power BI development.
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. RAW ROW COUNTS
   ========================================================= */

SELECT 'Customers' AS Dataset, COUNT(*) AS TotalRows
FROM raw.olist_customers

UNION ALL
SELECT 'Geolocation', COUNT(*)
FROM raw.olist_geolocation

UNION ALL
SELECT 'Orders', COUNT(*)
FROM raw.olist_orders

UNION ALL
SELECT 'Order Items', COUNT(*)
FROM raw.olist_order_items

UNION ALL
SELECT 'Payments', COUNT(*)
FROM raw.olist_order_payments

UNION ALL
SELECT 'Reviews', COUNT(*)
FROM raw.olist_order_reviews

UNION ALL
SELECT 'Products', COUNT(*)
FROM raw.olist_products

UNION ALL
SELECT 'Sellers', COUNT(*)
FROM raw.olist_sellers

UNION ALL
SELECT 'Category Translation', COUNT(*)
FROM raw.product_category_name_translation;
GO


/* =========================================================
   2. RAW VS STAGING COUNTS
   ========================================================= */

SELECT
    'Customers' AS Dataset,
    (SELECT COUNT(*) FROM raw.olist_customers) AS RawRows,
    (SELECT COUNT(*) FROM stg.olist_customers) AS StagingRows

UNION ALL

SELECT
    'Geolocation',
    (SELECT COUNT(*) FROM raw.olist_geolocation),
    (SELECT COUNT(*) FROM stg.olist_geolocation)

UNION ALL

SELECT
    'Orders',
    (SELECT COUNT(*) FROM raw.olist_orders),
    (SELECT COUNT(*) FROM stg.olist_orders)

UNION ALL

SELECT
    'Order Items',
    (SELECT COUNT(*) FROM raw.olist_order_items),
    (SELECT COUNT(*) FROM stg.olist_order_items)

UNION ALL

SELECT
    'Payments',
    (SELECT COUNT(*) FROM raw.olist_order_payments),
    (SELECT COUNT(*) FROM stg.olist_order_payments)

UNION ALL

SELECT
    'Reviews',
    (SELECT COUNT(*) FROM raw.olist_order_reviews),
    (SELECT COUNT(*) FROM stg.olist_order_reviews)

UNION ALL

SELECT
    'Products',
    (SELECT COUNT(*) FROM raw.olist_products),
    (SELECT COUNT(*) FROM stg.olist_products)

UNION ALL

SELECT
    'Sellers',
    (SELECT COUNT(*) FROM raw.olist_sellers),
    (SELECT COUNT(*) FROM stg.olist_sellers)

UNION ALL

SELECT
    'Category Translation',
    (SELECT COUNT(*) FROM raw.product_category_name_translation),
    (SELECT COUNT(*) FROM stg.product_category_name_translation);
GO


/* =========================================================
   3. DIMENSION COUNTS
   ========================================================= */

SELECT 'DimDate' AS ObjectName, COUNT(*) AS TotalRows
FROM dw.DimDate

UNION ALL
SELECT 'DimLocation', COUNT(*)
FROM dw.DimLocation

UNION ALL
SELECT 'DimCustomer', COUNT(*)
FROM dw.DimCustomer

UNION ALL
SELECT 'DimProduct', COUNT(*)
FROM dw.DimProduct

UNION ALL
SELECT 'DimSeller', COUNT(*)
FROM dw.DimSeller

UNION ALL
SELECT 'DimPaymentType', COUNT(*)
FROM dw.DimPaymentType;
GO


/* =========================================================
   4. FACT COUNTS
   ========================================================= */

SELECT 'FactOrder' AS ObjectName, COUNT(*) AS TotalRows
FROM dw.FactOrder

UNION ALL
SELECT 'FactSalesItem', COUNT(*)
FROM dw.FactSalesItem

UNION ALL
SELECT 'FactPayment', COUNT(*)
FROM dw.FactPayment;
GO


/* =========================================================
   5. FACT GRAIN CHECK
   Expected: all 0
   ========================================================= */

SELECT
    'FactOrder duplicate grain' AS CheckName,
    COUNT(*) AS IssueGroups
FROM
(
    SELECT OrderID
    FROM dw.FactOrder
    GROUP BY OrderID
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'FactSalesItem duplicate grain',
    COUNT(*)
FROM
(
    SELECT OrderID, OrderItemID
    FROM dw.FactSalesItem
    GROUP BY OrderID, OrderItemID
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'FactPayment duplicate grain',
    COUNT(*)
FROM
(
    SELECT OrderID, PaymentSequential
    FROM dw.FactPayment
    GROUP BY OrderID, PaymentSequential
    HAVING COUNT(*) > 1
) AS x;
GO


/* =========================================================
   6. UNKNOWN KEY USAGE IN FACTS
   Expected: all 0
   ========================================================= */

SELECT
    SUM(CASE WHEN CustomerKey = 0 THEN 1 ELSE 0 END)
        AS FactOrderUnknownCustomers
FROM dw.FactOrder;
GO


SELECT
    SUM(CASE WHEN CustomerKey = 0 THEN 1 ELSE 0 END)
        AS UnknownCustomers,

    SUM(CASE WHEN ProductKey = 0 THEN 1 ELSE 0 END)
        AS UnknownProducts,

    SUM(CASE WHEN SellerKey = 0 THEN 1 ELSE 0 END)
        AS UnknownSellers

FROM dw.FactSalesItem;
GO


SELECT
    SUM(CASE WHEN CustomerKey = 0 THEN 1 ELSE 0 END)
        AS UnknownCustomers,

    SUM(CASE WHEN PaymentTypeKey = 0 THEN 1 ELSE 0 END)
        AS UnknownPaymentTypes

FROM dw.FactPayment;
GO


/* =========================================================
   7. DELIVERY VALIDATION
   ========================================================= */

SELECT
    SUM(CASE WHEN DeliveryDateKey IS NULL THEN 1 ELSE 0 END)
        AS MissingDeliveryDate,

    SUM(CASE WHEN DeliveryDays IS NULL THEN 1 ELSE 0 END)
        AS MissingDeliveryDays,

    SUM(CASE WHEN DelayDays IS NULL THEN 1 ELSE 0 END)
        AS MissingDelayDays,

    SUM(CASE WHEN OnTimeFlag IS NULL THEN 1 ELSE 0 END)
        AS MissingOnTimeFlags

FROM dw.FactOrder;
GO


/* =========================================================
   8. REVIEW VALIDATION
   ========================================================= */

SELECT
    SUM(CASE WHEN ReviewScore IS NULL THEN 1 ELSE 0 END)
        AS OrdersWithoutReview,

    SUM(
        CASE
            WHEN ReviewScore IS NOT NULL
             AND ReviewScore <> FLOOR(ReviewScore)
            THEN 1
            ELSE 0
        END
    ) AS FractionalReviewScores

FROM dw.FactOrder;
GO


/* =========================================================
   9. DATA MART ROW COUNTS
   ========================================================= */

SELECT
    'vw_SalesPerformance' AS ViewName,
    COUNT(*) AS TotalRows
FROM mart.vw_SalesPerformance

UNION ALL

SELECT
    'vw_DeliveryPerformance',
    COUNT(*)
FROM mart.vw_DeliveryPerformance

UNION ALL

SELECT
    'vw_PaymentAnalysis',
    COUNT(*)
FROM mart.vw_PaymentAnalysis;
GO


/* =========================================================
   10. EXECUTIVE KPI SNAPSHOT
   ========================================================= */

SELECT *
FROM mart.vw_ExecutiveKPIs;
GO


/* =========================================================
   11. FOREIGN KEY AUDIT
   ========================================================= */

SELECT
    fk.name AS ForeignKeyName,

    OBJECT_NAME(fk.parent_object_id)
        AS FactTable,

    OBJECT_NAME(fk.referenced_object_id)
        AS DimensionTable

FROM sys.foreign_keys AS fk

WHERE OBJECT_SCHEMA_NAME(
    fk.parent_object_id
) = 'dw'

AND OBJECT_NAME(
    fk.parent_object_id
) LIKE 'Fact%'

ORDER BY
    FactTable,
    ForeignKeyName;
GO


/* =========================================================
   12. MART OBJECT AUDIT
   ========================================================= */

SELECT
    TABLE_SCHEMA,
    TABLE_NAME

FROM INFORMATION_SCHEMA.VIEWS

WHERE TABLE_SCHEMA = 'mart'

ORDER BY TABLE_NAME;
GO