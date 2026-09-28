/* =========================================================
   FILE: 06_mart_views.sql
   PURPOSE:
   Create analytical MART views for Power BI
   ========================================================= */


USE OlistDWBI;
GO


/* =========================================================
   1. EXECUTIVE KPI VIEW
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_ExecutiveKPIs
AS
SELECT
    /* -----------------------------------------------------
       Sales
       ----------------------------------------------------- */

    (
        SELECT SUM(Price)
        FROM dw.FactSalesItem
    ) AS SalesValue,

    (
        SELECT SUM(FreightValue)
        FROM dw.FactSalesItem
    ) AS FreightValue,

    (
        SELECT SUM(ItemTotal)
        FROM dw.FactSalesItem
    ) AS TotalItemValue,


    /* -----------------------------------------------------
       Orders
       ----------------------------------------------------- */

    (
        SELECT COUNT(*)
        FROM dw.FactOrder
    ) AS Orders,


    /* -----------------------------------------------------
       Customers
       ----------------------------------------------------- */

    (
        SELECT COUNT(DISTINCT c.CustomerUniqueID)
        FROM dw.FactOrder fo
        INNER JOIN dw.DimCustomer c
            ON fo.CustomerKey = c.CustomerKey
    ) AS Customers,


    /* -----------------------------------------------------
       Average Order Value
       ----------------------------------------------------- */

    CAST(
        (
            SELECT SUM(Price)
            FROM dw.FactSalesItem
        )
        /
        NULLIF(
            (
                SELECT COUNT(*)
                FROM dw.FactOrder
            ),
            0
        )
        AS DECIMAL(12,2)
    ) AS AOV,


    /* -----------------------------------------------------
       Average Delivery Days
       ----------------------------------------------------- */

    CAST(
        (
            SELECT AVG(
                CAST(DeliveryDays AS DECIMAL(10,2))
            )
            FROM dw.FactOrder
            WHERE DeliveryDays IS NOT NULL
        )
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays,


    /* -----------------------------------------------------
       On-Time Delivery Percentage
       ----------------------------------------------------- */

    CAST(
        100.0 *
        (
            SELECT COUNT(*)
            FROM dw.FactOrder
            WHERE OnTimeFlag = 1
        )
        /
        NULLIF(
            (
                SELECT COUNT(*)
                FROM dw.FactOrder
                WHERE OnTimeFlag IS NOT NULL
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS OnTimeDeliveryPercentage,


    /* -----------------------------------------------------
       Average Review Score
       ----------------------------------------------------- */

    CAST(
        (
            SELECT AVG(ReviewScore)
            FROM dw.FactOrder
            WHERE ReviewScore IS NOT NULL
        )
        AS DECIMAL(10,2)
    ) AS AverageReviewScore;
GO



/* =========================================================
   2. SALES PERFORMANCE VIEW
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_SalesPerformance
AS
SELECT
    /* -----------------------------------------------------
       Date
       ----------------------------------------------------- */

    d.FullDate,
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthName,


    /* -----------------------------------------------------
       Customer Location
       ----------------------------------------------------- */

    c.CustomerState,
    c.CustomerCity,


    /* -----------------------------------------------------
       Product
       ----------------------------------------------------- */

    p.ProductCategoryName,
    p.ProductCategoryEnglish,


    /* -----------------------------------------------------
       Seller Location
       ----------------------------------------------------- */

    s.SellerState,
    s.SellerCity,


    /* -----------------------------------------------------
       Measures
       ----------------------------------------------------- */

    SUM(f.Price) AS SalesValue,

    SUM(f.FreightValue) AS FreightValue,

    SUM(f.ItemTotal) AS TotalItemValue,

    SUM(f.ItemCount) AS Items,

    COUNT(DISTINCT f.OrderID) AS Orders


FROM dw.FactSalesItem f


INNER JOIN dw.DimDate d
    ON f.PurchaseDateKey = d.DateKey


INNER JOIN dw.DimCustomer c
    ON f.CustomerKey = c.CustomerKey


INNER JOIN dw.DimProduct p
    ON f.ProductKey = p.ProductKey


INNER JOIN dw.DimSeller s
    ON f.SellerKey = s.SellerKey


GROUP BY
    d.FullDate,
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthName,
    c.CustomerState,
    c.CustomerCity,
    p.ProductCategoryName,
    p.ProductCategoryEnglish,
    s.SellerState,
    s.SellerCity;
GO



/* =========================================================
   3. DELIVERY PERFORMANCE VIEW
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_DeliveryPerformance
AS
SELECT
    /* -----------------------------------------------------
       Date
       ----------------------------------------------------- */

    d.FullDate,
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthName,


    /* -----------------------------------------------------
       Customer Location
       ----------------------------------------------------- */

    c.CustomerState,
    c.CustomerCity,


    /* -----------------------------------------------------
       Order Status
       ----------------------------------------------------- */

    fo.OrderStatus,


    /* -----------------------------------------------------
       Measures
       ----------------------------------------------------- */

    COUNT(*) AS Orders,

    SUM(
        CASE
            WHEN fo.OnTimeFlag = 1
            THEN 1
            ELSE 0
        END
    ) AS OnTimeOrders,

    SUM(
        CASE
            WHEN fo.OnTimeFlag = 0
            THEN 1
            ELSE 0
        END
    ) AS LateOrders,

    SUM(
        CASE
            WHEN fo.OrderStatus <> 'delivered'
                 AND fo.OnTimeFlag IS NULL
            THEN 1
            ELSE 0
        END
    ) AS NotYetDeliveredOrders,

    AVG(
        CAST(fo.DeliveryDays AS DECIMAL(10,2))
    ) AS AverageDeliveryDays,

    AVG(
        CAST(fo.ReviewScore AS DECIMAL(10,2))
    ) AS AverageReviewScore


FROM dw.FactOrder fo


INNER JOIN dw.DimDate d
    ON fo.PurchaseDateKey = d.DateKey


INNER JOIN dw.DimCustomer c
    ON fo.CustomerKey = c.CustomerKey


GROUP BY
    d.FullDate,
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthName,
    c.CustomerState,
    c.CustomerCity,
    fo.OrderStatus;
GO



/* =========================================================
   4. PAYMENT ANALYSIS VIEW
   ========================================================= */

CREATE OR ALTER VIEW mart.vw_PaymentAnalysis
AS
SELECT
    /* -----------------------------------------------------
       Date
       ----------------------------------------------------- */

    d.FullDate,
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthName,


    /* -----------------------------------------------------
       Customer Location
       ----------------------------------------------------- */

    c.CustomerState,


    /* -----------------------------------------------------
       Payment Type
       ----------------------------------------------------- */

    pt.PaymentType,


    /* -----------------------------------------------------
       Measures
       ----------------------------------------------------- */

    COUNT(*) AS PaymentTransactions,

    SUM(fp.PaymentCount) AS PaymentCount,

    SUM(fp.PaymentValue) AS PaymentValue,

    AVG(
        CAST(fp.PaymentValue AS DECIMAL(18,2))
    ) AS AveragePaymentValue,

    AVG(
        CAST(fp.Installments AS DECIMAL(10,2))
    ) AS AverageInstallments


FROM dw.FactPayment fp


INNER JOIN dw.DimDate d
    ON fp.PaymentDateKey = d.DateKey


INNER JOIN dw.DimCustomer c
    ON fp.CustomerKey = c.CustomerKey


INNER JOIN dw.DimPaymentType pt
    ON fp.PaymentTypeKey = pt.PaymentTypeKey


GROUP BY
    d.FullDate,
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthName,
    c.CustomerState,
    pt.PaymentType;
GO