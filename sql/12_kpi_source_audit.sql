/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
12_kpi_source_audit.sql

Purpose:
Audits the relationship between order-item values and
payment values before defining executive BI KPIs.
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. BASIC TOTALS
   ========================================================= */

SELECT
    SUM(Price) AS ProductPriceTotal,
    SUM(FreightValue) AS FreightTotal,
    SUM(ItemTotal) AS ItemAndFreightTotal
FROM dw.FactSalesItem;
GO


SELECT
    SUM(PaymentValue) AS PaymentTotal
FROM dw.FactPayment;
GO


/* =========================================================
   2. DISTINCT ORDERS REPRESENTED BY EACH FACT
   ========================================================= */

SELECT
    (SELECT COUNT(DISTINCT OrderID)
     FROM dw.FactOrder)
        AS OrdersInFactOrder,

    (SELECT COUNT(DISTINCT OrderID)
     FROM dw.FactSalesItem)
        AS OrdersWithItems,

    (SELECT COUNT(DISTINCT OrderID)
     FROM dw.FactPayment)
        AS OrdersWithPayments;
GO


/* =========================================================
   3. ORDERS WITHOUT SALES ITEMS
   ========================================================= */

SELECT
    COUNT(*) AS OrdersWithoutItems
FROM dw.FactOrder AS o

LEFT JOIN
(
    SELECT DISTINCT OrderID
    FROM dw.FactSalesItem
) AS i
    ON o.OrderID = i.OrderID

WHERE i.OrderID IS NULL;
GO


/* =========================================================
   4. STATUS OF ORDERS WITHOUT ITEMS
   ========================================================= */

SELECT
    o.OrderStatus,
    COUNT(*) AS OrdersWithoutItems
FROM dw.FactOrder AS o

LEFT JOIN
(
    SELECT DISTINCT OrderID
    FROM dw.FactSalesItem
) AS i
    ON o.OrderID = i.OrderID

WHERE i.OrderID IS NULL

GROUP BY o.OrderStatus

ORDER BY OrdersWithoutItems DESC;
GO


/* =========================================================
   5. ORDER-LEVEL ITEM VALUE VS PAYMENT VALUE
   ========================================================= */

;WITH ItemTotals AS
(
    SELECT
        OrderID,
        SUM(ItemTotal) AS ItemAndFreightValue
    FROM dw.FactSalesItem
    GROUP BY OrderID
),

PaymentTotals AS
(
    SELECT
        OrderID,
        SUM(PaymentValue) AS PaymentValue
    FROM dw.FactPayment
    GROUP BY OrderID
),

Comparison AS
(
    SELECT
        COALESCE(i.OrderID, p.OrderID) AS OrderID,

        COALESCE(i.ItemAndFreightValue, 0)
            AS ItemAndFreightValue,

        COALESCE(p.PaymentValue, 0)
            AS PaymentValue,

        COALESCE(p.PaymentValue, 0)
        -
        COALESCE(i.ItemAndFreightValue, 0)
            AS Difference

    FROM ItemTotals AS i

    FULL OUTER JOIN PaymentTotals AS p
        ON i.OrderID = p.OrderID
)

SELECT
    COUNT(*) AS ComparedOrders,

    SUM(
        CASE
            WHEN ABS(Difference) < 0.01
                THEN 1
            ELSE 0
        END
    ) AS MatchingOrders,

    SUM(
        CASE
            WHEN ABS(Difference) >= 0.01
                THEN 1
            ELSE 0
        END
    ) AS DifferentOrders,

    SUM(ItemAndFreightValue)
        AS ItemAndFreightTotal,

    SUM(PaymentValue)
        AS PaymentTotal,

    SUM(Difference)
        AS TotalDifference

FROM Comparison;
GO


/* =========================================================
   6. LARGEST ORDER-LEVEL DIFFERENCES
   ========================================================= */

;WITH ItemTotals AS
(
    SELECT
        OrderID,
        SUM(ItemTotal) AS ItemAndFreightValue
    FROM dw.FactSalesItem
    GROUP BY OrderID
),

PaymentTotals AS
(
    SELECT
        OrderID,
        SUM(PaymentValue) AS PaymentValue
    FROM dw.FactPayment
    GROUP BY OrderID
)

SELECT TOP (20)
    COALESCE(i.OrderID, p.OrderID) AS OrderID,

    COALESCE(i.ItemAndFreightValue, 0)
        AS ItemAndFreightValue,

    COALESCE(p.PaymentValue, 0)
        AS PaymentValue,

    COALESCE(p.PaymentValue, 0)
    -
    COALESCE(i.ItemAndFreightValue, 0)
        AS Difference

FROM ItemTotals AS i

FULL OUTER JOIN PaymentTotals AS p
    ON i.OrderID = p.OrderID

ORDER BY
    ABS(
        COALESCE(p.PaymentValue, 0)
        -
        COALESCE(i.ItemAndFreightValue, 0)
    ) DESC;
GO


/* =========================================================
   7. DELIVERY KPI BASE
   ========================================================= */

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

FROM dw.FactOrder;
GO