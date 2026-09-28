/* =========================================================
   FILE: 07_verification.sql
   PURPOSE:
   Verify database objects, row counts, data totals,
   MART views and RAW -> STG -> DW consistency
   ========================================================= */


USE OlistDWBI;
GO


/* =========================================================
   1. VERIFY DATABASE
   ========================================================= */

SELECT
    DB_NAME() AS CurrentDatabase;
GO


/* =========================================================
   2. VERIFY SCHEMAS
   ========================================================= */

SELECT
    name AS SchemaName
FROM sys.schemas
WHERE name IN
(
    'raw',
    'stg',
    'dw',
    'mart'
)
ORDER BY name;
GO


/* =========================================================
   3. VERIFY RAW TABLE ROW COUNTS
   ========================================================= */

SELECT
    'raw.olist_customers' AS TableName,
    COUNT(*) AS TotalRows
FROM raw.olist_customers

UNION ALL

SELECT
    'raw.olist_geolocation',
    COUNT(*)
FROM raw.olist_geolocation

UNION ALL

SELECT
    'raw.olist_orders',
    COUNT(*)
FROM raw.olist_orders

UNION ALL

SELECT
    'raw.olist_order_items',
    COUNT(*)
FROM raw.olist_order_items

UNION ALL

SELECT
    'raw.olist_order_payments',
    COUNT(*)
FROM raw.olist_order_payments

UNION ALL

SELECT
    'raw.olist_order_reviews',
    COUNT(*)
FROM raw.olist_order_reviews

UNION ALL

SELECT
    'raw.olist_products',
    COUNT(*)
FROM raw.olist_products

UNION ALL

SELECT
    'raw.olist_sellers',
    COUNT(*)
FROM raw.olist_sellers

UNION ALL

SELECT
    'raw.product_category_name_translation',
    COUNT(*)
FROM raw.product_category_name_translation

ORDER BY TableName;
GO


/* =========================================================
   4. VERIFY STAGING TABLE ROW COUNTS
   ========================================================= */

SELECT
    'stg.olist_customers' AS TableName,
    COUNT(*) AS TotalRows
FROM stg.olist_customers

UNION ALL

SELECT
    'stg.olist_geolocation',
    COUNT(*)
FROM stg.olist_geolocation

UNION ALL

SELECT
    'stg.olist_orders',
    COUNT(*)
FROM stg.olist_orders

UNION ALL

SELECT
    'stg.olist_order_items',
    COUNT(*)
FROM stg.olist_order_items

UNION ALL

SELECT
    'stg.olist_order_payments',
    COUNT(*)
FROM stg.olist_order_payments

UNION ALL

SELECT
    'stg.olist_order_reviews',
    COUNT(*)
FROM stg.olist_order_reviews

UNION ALL

SELECT
    'stg.olist_products',
    COUNT(*)
FROM stg.olist_products

UNION ALL

SELECT
    'stg.olist_sellers',
    COUNT(*)
FROM stg.olist_sellers

UNION ALL

SELECT
    'stg.product_category_translation',
    COUNT(*)
FROM stg.product_category_translation

ORDER BY TableName;
GO


/* =========================================================
   5. VERIFY DIMENSION TABLE ROW COUNTS
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


/* =========================================================
   6. VERIFY FACT TABLE ROW COUNTS
   ========================================================= */

SELECT
    'dw.FactOrder' AS TableName,
    COUNT(*) AS TotalRows
FROM dw.FactOrder

UNION ALL

SELECT
    'dw.FactSalesItem',
    COUNT(*)
FROM dw.FactSalesItem

UNION ALL

SELECT
    'dw.FactPayment',
    COUNT(*)
FROM dw.FactPayment

ORDER BY TableName;
GO


/* =========================================================
   7. VERIFY MART VIEW ROW COUNTS
   ========================================================= */

SELECT
    'mart.vw_ExecutiveKPIs' AS ViewName,
    COUNT(*) AS TotalRows
FROM mart.vw_ExecutiveKPIs

UNION ALL

SELECT
    'mart.vw_SalesPerformance',
    COUNT(*)
FROM mart.vw_SalesPerformance

UNION ALL

SELECT
    'mart.vw_DeliveryPerformance',
    COUNT(*)
FROM mart.vw_DeliveryPerformance

UNION ALL

SELECT
    'mart.vw_PaymentAnalysis',
    COUNT(*)
FROM mart.vw_PaymentAnalysis

ORDER BY ViewName;
GO


/* =========================================================
   8. VERIFY MART VIEWS EXIST
   ========================================================= */

SELECT
    TABLE_SCHEMA AS SchemaName,
    TABLE_NAME AS ViewName
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'mart'
ORDER BY TABLE_NAME;
GO


/* =========================================================
   9. EXECUTIVE KPI VALUES
   ========================================================= */

SELECT
    *
FROM mart.vw_ExecutiveKPIs;
GO


/* =========================================================
   10. SALES TOTALS
   ========================================================= */

SELECT
    SUM(Price) AS SalesValue,
    SUM(FreightValue) AS FreightValue,
    SUM(ItemTotal) AS TotalItemValue,
    SUM(ItemCount) AS Items,
    COUNT(DISTINCT OrderID) AS Orders
FROM dw.FactSalesItem;
GO


/* =========================================================
   11. DELIVERY TOTALS
   ========================================================= */

SELECT
    COUNT(*) AS TotalOrders,
    SUM(
        CASE
            WHEN OnTimeFlag = 1 THEN 1
            ELSE 0
        END
    ) AS OnTimeOrders,
    SUM(
        CASE
            WHEN OnTimeFlag = 0 THEN 1
            ELSE 0
        END
    ) AS LateOrders,
    SUM(
        CASE
            WHEN OnTimeFlag IS NULL THEN 1
            ELSE 0
        END
    ) AS NotYetEvaluatedOrders,
    AVG(
        CAST(DeliveryDays AS DECIMAL(10,2))
    ) AS AverageDeliveryDays
FROM dw.FactOrder;
GO


/* =========================================================
   12. PAYMENT TOTALS
   ========================================================= */

SELECT
    COUNT(*) AS PaymentRows,
    SUM(PaymentValue) AS PaymentValue,
    AVG(
        CAST(PaymentValue AS DECIMAL(18,2))
    ) AS AveragePaymentValue,
    AVG(
        CAST(Installments AS DECIMAL(10,2))
    ) AS AverageInstallments
FROM dw.FactPayment;
GO


/* =========================================================
   13. REVIEW SCORE CHECK
   ========================================================= */

SELECT
    COUNT(*) AS OrdersWithReviewScore,
    AVG(
        CAST(ReviewScore AS DECIMAL(10,2))
    ) AS AverageReviewScore
FROM dw.FactOrder
WHERE ReviewScore IS NOT NULL;
GO


/* =========================================================
   14. RAW -> STAGING -> DW ROW COUNT AUDIT
   ========================================================= */

SELECT
    'Customers' AS Dataset,
    (SELECT COUNT(*) FROM raw.olist_customers) AS RawRows,
    (SELECT COUNT(*) FROM stg.olist_customers) AS StagingRows,
    (SELECT COUNT(*) FROM dw.DimCustomer) AS DWRows

UNION ALL

SELECT
    'Orders',
    (SELECT COUNT(*) FROM raw.olist_orders),
    (SELECT COUNT(*) FROM stg.olist_orders),
    (SELECT COUNT(*) FROM dw.FactOrder)

UNION ALL

SELECT
    'Order Items',
    (SELECT COUNT(*) FROM raw.olist_order_items),
    (SELECT COUNT(*) FROM stg.olist_order_items),
    (SELECT COUNT(*) FROM dw.FactSalesItem)

UNION ALL

SELECT
    'Payments',
    (SELECT COUNT(*) FROM raw.olist_order_payments),
    (SELECT COUNT(*) FROM stg.olist_order_payments),
    (SELECT COUNT(*) FROM dw.FactPayment)

ORDER BY Dataset;
GO


/* =========================================================
   15. ORDER DATA QUALITY - MISSING VALUES
   ========================================================= */

SELECT
    COUNT(*) AS TotalOrders,

    SUM(
        CASE
            WHEN order_approved_at IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingApprovedDate,

    SUM(
        CASE
            WHEN order_delivered_carrier_date IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingCarrierDate,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingCustomerDeliveryDate

FROM stg.olist_orders;
GO


/* =========================================================
   16. REVIEW DATA QUALITY
   ========================================================= */

SELECT
    COUNT(*) AS TotalReviewRows,
    COUNT(DISTINCT review_id) AS UniqueReviewIDs,
    COUNT(DISTINCT order_id) AS OrdersWithReviews
FROM stg.olist_order_reviews;
GO


/* =========================================================
   17. DUPLICATE REVIEW IDs
   ========================================================= */

SELECT
    review_id,
    COUNT(*) AS Occurrences
FROM stg.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY Occurrences DESC;
GO


/* =========================================================
   18. ORDERS WITH MULTIPLE UNIQUE REVIEW IDs
   ========================================================= */

SELECT
    order_id,
    COUNT(DISTINCT review_id) AS UniqueReviewIDs
FROM stg.olist_order_reviews
GROUP BY order_id
HAVING COUNT(DISTINCT review_id) > 1
ORDER BY UniqueReviewIDs DESC;
GO


/* =========================================================
   19. PRIMARY KEY CONSTRAINT AUDIT
   ========================================================= */

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    kc.name AS PrimaryKeyName
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.key_constraints kc
    ON t.object_id = kc.parent_object_id
WHERE kc.type = 'PK'
  AND s.name = 'dw'
ORDER BY t.name;
GO


/* =========================================================
   20. DW TABLE OBJECT AUDIT
   ========================================================= */

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    t.create_date AS CreatedDate
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE s.name = 'dw'
ORDER BY t.name;
GO


/* =========================================================
   21. MART OBJECT AUDIT
   ========================================================= */

SELECT
    s.name AS SchemaName,
    o.name AS ObjectName,
    o.type_desc AS ObjectType
FROM sys.objects o
INNER JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE s.name = 'mart'
ORDER BY o.name;
GO


/* =========================================================
   22. FINAL DW TABLE COUNTS
   ========================================================= */

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p
    ON t.object_id = p.object_id
WHERE s.name = 'dw'
  AND p.index_id IN (0, 1)
GROUP BY
    s.name,
    t.name
ORDER BY
    t.name;
GO


/* =========================================================
   23. FINAL MART VIEW COUNTS
   ========================================================= */

SELECT
    'vw_ExecutiveKPIs' AS ViewName,
    COUNT(*) AS TotalRows
FROM mart.vw_ExecutiveKPIs

UNION ALL

SELECT
    'vw_SalesPerformance',
    COUNT(*)
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
FROM mart.vw_PaymentAnalysis

ORDER BY ViewName;
GO


/* =========================================================
   24. SAMPLE SALES PERFORMANCE DATA
   ========================================================= */

SELECT TOP 20
    *
FROM mart.vw_SalesPerformance
ORDER BY FullDate;
GO


/* =========================================================
   25. SAMPLE DELIVERY PERFORMANCE DATA
   ========================================================= */

SELECT TOP 20
    *
FROM mart.vw_DeliveryPerformance
ORDER BY FullDate;
GO


/* =========================================================
   26. SAMPLE PAYMENT ANALYSIS DATA
   ========================================================= */

SELECT TOP 20
    *
FROM mart.vw_PaymentAnalysis
ORDER BY FullDate;
GO