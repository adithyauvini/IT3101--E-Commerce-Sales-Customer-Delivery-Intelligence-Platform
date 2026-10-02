/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
13_create_mart_views.sql

Purpose:
Creates analytical Data Mart views for Power BI.

Views:
    mart.vw_ExecutiveKPIs
    mart.vw_SalesPerformance
    mart.vw_DeliveryPerformance
    mart.vw_PaymentAnalysis
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. EXECUTIVE KPI VIEW
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_ExecutiveKPIs
AS

WITH OrderMetrics AS
(
    SELECT
        COUNT(*) AS TotalOrders,

        SUM(
            CASE
                WHEN DeliveryDateKey IS NOT NULL
                    THEN 1
                ELSE 0
            END
        ) AS OrdersWithDeliveryDate,

        SUM(
            CASE
                WHEN OnTimeFlag = 1
                    THEN 1
                ELSE 0
            END
        ) AS OnTimeOrders,

        SUM(
            CASE
                WHEN OnTimeFlag = 0
                    THEN 1
                ELSE 0
            END
        ) AS LateOrders,

        AVG(
            CAST(
                DeliveryDays
                AS DECIMAL(18,2)
            )
        ) AS AverageDeliveryDays,

        AVG(
            CAST(
                ReviewScore
                AS DECIMAL(18,2)
            )
        ) AS AverageReviewScore

    FROM dw.FactOrder
),

SalesMetrics AS
(
    SELECT
        SUM(Price) AS ProductSalesValue,

        SUM(FreightValue) AS FreightValue,

        SUM(ItemTotal) AS GrossItemValue,

        SUM(ItemCount) AS TotalItems,

        COUNT(DISTINCT OrderID) AS OrdersWithItems

    FROM dw.FactSalesItem
),

PaymentMetrics AS
(
    SELECT
        SUM(PaymentValue) AS TotalPaymentValue,

        SUM(PaymentCount) AS PaymentTransactions,

        COUNT(DISTINCT OrderID) AS OrdersWithPayments

    FROM dw.FactPayment
),

CustomerMetrics AS
(
    SELECT
        COUNT(
            DISTINCT c.CustomerUniqueID
        ) AS UniqueCustomers

    FROM dw.FactOrder AS f

    INNER JOIN dw.DimCustomer AS c
        ON f.CustomerKey =
           c.CustomerKey

    WHERE c.CustomerKey <> 0
)

SELECT
    o.TotalOrders,

    s.OrdersWithItems,

    p.OrdersWithPayments,

    c.UniqueCustomers,

    s.TotalItems,

    s.ProductSalesValue,

    s.FreightValue,

    s.GrossItemValue,

    p.TotalPaymentValue,

    CAST(
        s.GrossItemValue
        /
        NULLIF(
            CAST(s.OrdersWithItems AS DECIMAL(18,2)),
            0
        )
        AS DECIMAL(18,2)
    ) AS AverageOrderValue,

    o.OrdersWithDeliveryDate,

    o.OnTimeOrders,

    o.LateOrders,

    CAST(
        o.OnTimeOrders * 100.0
        /
        NULLIF(o.OrdersWithDeliveryDate, 0)
        AS DECIMAL(6,2)
    ) AS OnTimeDeliveryPercentage,

    CAST(
        o.AverageDeliveryDays
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays,

    CAST(
        o.AverageReviewScore
        AS DECIMAL(10,2)
    ) AS AverageReviewScore,

    p.PaymentTransactions

FROM OrderMetrics AS o

CROSS JOIN SalesMetrics AS s

CROSS JOIN PaymentMetrics AS p

CROSS JOIN CustomerMetrics AS c;
GO


/* =========================================================
   2. SALES PERFORMANCE VIEW

   Grain:
   One row per order item
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_SalesPerformance
AS

SELECT
    f.FactSalesItemKey,

    f.OrderID,

    f.OrderItemID,

    d.FullDate AS PurchaseDate,

    d.YearNumber,

    d.QuarterNumber,

    d.QuarterName,

    d.MonthNumber,

    d.MonthName,

    d.YearMonthKey,

    d.YearMonthLabel,

    c.CustomerID,

    c.CustomerUniqueID,

    customerLocation.ZipCodePrefix
        AS CustomerZipCodePrefix,

    customerLocation.City
        AS CustomerCity,

    customerLocation.State
        AS CustomerState,

    p.ProductID,

    p.ProductCategoryName,

    p.ProductCategoryEnglish,

    s.SellerID,

    sellerLocation.ZipCodePrefix
        AS SellerZipCodePrefix,

    sellerLocation.City
        AS SellerCity,

    sellerLocation.State
        AS SellerState,

    f.Price,

    f.FreightValue,

    f.ItemTotal,

    f.ItemCount

FROM dw.FactSalesItem AS f

INNER JOIN dw.DimDate AS d
    ON f.PurchaseDateKey =
       d.DateKey

INNER JOIN dw.DimCustomer AS c
    ON f.CustomerKey =
       c.CustomerKey

INNER JOIN dw.DimLocation AS customerLocation
    ON c.LocationKey =
       customerLocation.LocationKey

INNER JOIN dw.DimProduct AS p
    ON f.ProductKey =
       p.ProductKey

INNER JOIN dw.DimSeller AS s
    ON f.SellerKey =
       s.SellerKey

INNER JOIN dw.DimLocation AS sellerLocation
    ON s.LocationKey =
       sellerLocation.LocationKey;
GO


/* =========================================================
   3. DELIVERY PERFORMANCE VIEW

   Grain:
   One row per order
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_DeliveryPerformance
AS

SELECT
    f.FactOrderKey,

    f.OrderID,

    c.CustomerID,

    c.CustomerUniqueID,

    l.ZipCodePrefix
        AS CustomerZipCodePrefix,

    l.City
        AS CustomerCity,

    l.State
        AS CustomerState,

    purchaseDate.FullDate
        AS PurchaseDate,

    purchaseDate.YearNumber,

    purchaseDate.QuarterNumber,

    purchaseDate.QuarterName,

    purchaseDate.MonthNumber,

    purchaseDate.MonthName,

    purchaseDate.YearMonthKey,

    purchaseDate.YearMonthLabel,

    deliveryDate.FullDate
        AS DeliveryDate,

    estimatedDate.FullDate
        AS EstimatedDeliveryDate,

    f.OrderStatus,

    f.OrderCount,

    f.DeliveryDays,

    f.DelayDays,

    f.OnTimeFlag,

    CASE
        WHEN f.OnTimeFlag = 1
            THEN 'On Time'

        WHEN f.OnTimeFlag = 0
            THEN 'Late'

        ELSE 'Not Delivered'
    END AS DeliveryStatus,

    f.ReviewScore

FROM dw.FactOrder AS f

INNER JOIN dw.DimCustomer AS c
    ON f.CustomerKey =
       c.CustomerKey

INNER JOIN dw.DimLocation AS l
    ON c.LocationKey =
       l.LocationKey

INNER JOIN dw.DimDate AS purchaseDate
    ON f.PurchaseDateKey =
       purchaseDate.DateKey

LEFT JOIN dw.DimDate AS deliveryDate
    ON f.DeliveryDateKey =
       deliveryDate.DateKey

INNER JOIN dw.DimDate AS estimatedDate
    ON f.EstimatedDeliveryDateKey =
       estimatedDate.DateKey;
GO


/* =========================================================
   4. PAYMENT ANALYSIS VIEW

   Grain:
   One row per payment transaction
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_PaymentAnalysis
AS

SELECT
    f.FactPaymentKey,

    f.OrderID,

    f.PaymentSequential,

    d.FullDate
        AS PurchaseDate,

    d.YearNumber,

    d.QuarterNumber,

    d.QuarterName,

    d.MonthNumber,

    d.MonthName,

    d.YearMonthKey,

    d.YearMonthLabel,

    c.CustomerID,

    c.CustomerUniqueID,

    l.ZipCodePrefix
        AS CustomerZipCodePrefix,

    l.City
        AS CustomerCity,

    l.State
        AS CustomerState,

    pt.PaymentType,

    f.PaymentInstallments,

    f.PaymentValue,

    f.PaymentCount

FROM dw.FactPayment AS f

INNER JOIN dw.DimDate AS d
    ON f.PurchaseDateKey =
       d.DateKey

INNER JOIN dw.DimCustomer AS c
    ON f.CustomerKey =
       c.CustomerKey

INNER JOIN dw.DimLocation AS l
    ON c.LocationKey =
       l.LocationKey

INNER JOIN dw.DimPaymentType AS pt
    ON f.PaymentTypeKey =
       pt.PaymentTypeKey;
GO


/* =========================================================
   5. VERIFY MART VIEWS
   ========================================================= */

SELECT
    TABLE_SCHEMA AS SchemaName,
    TABLE_NAME AS ViewName

FROM INFORMATION_SCHEMA.VIEWS

WHERE TABLE_SCHEMA = 'mart'

ORDER BY TABLE_NAME;
GO


/* =========================================================
   6. VERIFY EXECUTIVE KPIs
   ========================================================= */

SELECT *
FROM mart.vw_ExecutiveKPIs;
GO


/* =========================================================
   7. VERIFY MART GRAINS
   ========================================================= */

SELECT
    'vw_SalesPerformance'
        AS ViewName,

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