/* =========================================================
   FILE: 05_facts.sql
   PURPOSE:
   Create and populate the Fact Tables
   ========================================================= */


USE OlistDWBI;
GO


/* =========================================================
   1. FACT ORDER
   ========================================================= */

IF OBJECT_ID('dw.FactOrder', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactOrder
    (
        OrderKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderID VARCHAR(50) NOT NULL,
        CustomerKey INT NOT NULL,
        PurchaseDateKey INT NULL,
        DeliveryDateKey INT NULL,
        EstimatedDeliveryDateKey INT NULL,
        OrderStatus VARCHAR(50) NULL,
        OrderCount INT NOT NULL,
        DeliveryDays INT NULL,
        DelayDays INT NULL,
        OnTimeFlag INT NULL,
        ReviewScore INT NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate FactOrder
   --------------------------------------------------------- */

INSERT INTO dw.FactOrder
(
    OrderID,
    CustomerKey,
    PurchaseDateKey,
    DeliveryDateKey,
    EstimatedDeliveryDateKey,
    OrderStatus,
    OrderCount,
    DeliveryDays,
    DelayDays,
    OnTimeFlag,
    ReviewScore
)
SELECT
    o.order_id,
    c.CustomerKey,

    CONVERT(
        INT,
        CONVERT(
            CHAR(8),
            CAST(o.order_purchase_timestamp AS DATE),
            112
        )
    ) AS PurchaseDateKey,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN CONVERT(
            INT,
            CONVERT(
                CHAR(8),
                CAST(o.order_delivered_customer_date AS DATE),
                112
            )
        )
        ELSE NULL
    END AS DeliveryDateKey,

    CASE
        WHEN o.order_estimated_delivery_date IS NOT NULL
        THEN CONVERT(
            INT,
            CONVERT(
                CHAR(8),
                CAST(o.order_estimated_delivery_date AS DATE),
                112
            )
        )
        ELSE NULL
    END AS EstimatedDeliveryDateKey,

    o.order_status,

    1 AS OrderCount,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            DAY,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        )
        ELSE NULL
    END AS DeliveryDays,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(
            DAY,
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        )
        ELSE NULL
    END AS DelayDays,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
             OR o.order_estimated_delivery_date IS NULL
        THEN NULL

        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 1

        ELSE 0
    END AS OnTimeFlag,

    r.ReviewScore

FROM stg.olist_orders o

INNER JOIN dw.DimCustomer c
    ON o.customer_id = c.CustomerID

LEFT JOIN
(
    SELECT
        order_id,
        AVG(CAST(review_score AS DECIMAL(10,2))) AS ReviewScore
    FROM stg.olist_order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
) r
    ON o.order_id = r.order_id;
GO


/* =========================================================
   2. FACT SALES ITEM
   ========================================================= */

IF OBJECT_ID('dw.FactSalesItem', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactSalesItem
    (
        SalesItemKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderID VARCHAR(50) NOT NULL,
        OrderItemID INT NOT NULL,
        CustomerKey INT NOT NULL,
        ProductKey INT NOT NULL,
        SellerKey INT NOT NULL,
        PurchaseDateKey INT NOT NULL,
        Price DECIMAL(18,2) NULL,
        FreightValue DECIMAL(18,2) NULL,
        ItemTotal DECIMAL(18,2) NULL,
        ItemCount INT NOT NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate FactSalesItem
   --------------------------------------------------------- */

INSERT INTO dw.FactSalesItem
(
    OrderID,
    OrderItemID,
    CustomerKey,
    ProductKey,
    SellerKey,
    PurchaseDateKey,
    Price,
    FreightValue,
    ItemTotal,
    ItemCount
)
SELECT
    i.order_id,
    i.order_item_id,

    c.CustomerKey,

    p.ProductKey,

    s.SellerKey,

    CONVERT(
        INT,
        CONVERT(
            CHAR(8),
            CAST(o.order_purchase_timestamp AS DATE),
            112
        )
    ) AS PurchaseDateKey,

    i.price,

    i.freight_value,

    ISNULL(i.price, 0)
        + ISNULL(i.freight_value, 0) AS ItemTotal,

    1 AS ItemCount

FROM stg.olist_order_items i

INNER JOIN stg.olist_orders o
    ON i.order_id = o.order_id

INNER JOIN dw.DimCustomer c
    ON o.customer_id = c.CustomerID

INNER JOIN dw.DimProduct p
    ON i.product_id = p.ProductID

INNER JOIN dw.DimSeller s
    ON i.seller_id = s.SellerID;
GO


/* =========================================================
   3. FACT PAYMENT
   ========================================================= */

IF OBJECT_ID('dw.FactPayment', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactPayment
    (
        PaymentFactKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderID VARCHAR(50) NOT NULL,
        PaymentSequential INT NOT NULL,
        CustomerKey INT NOT NULL,
        PaymentDateKey INT NOT NULL,
        PaymentTypeKey INT NOT NULL,
        PaymentValue DECIMAL(18,2) NULL,
        Installments INT NULL,
        PaymentCount INT NOT NULL
    );
END;
GO


/* ---------------------------------------------------------
   Populate FactPayment
   --------------------------------------------------------- */

INSERT INTO dw.FactPayment
(
    OrderID,
    PaymentSequential,
    CustomerKey,
    PaymentDateKey,
    PaymentTypeKey,
    PaymentValue,
    Installments,
    PaymentCount
)
SELECT
    p.order_id,

    p.payment_sequential,

    c.CustomerKey,

    CONVERT(
        INT,
        CONVERT(
            CHAR(8),
            CAST(o.order_purchase_timestamp AS DATE),
            112
        )
    ) AS PaymentDateKey,

    pt.PaymentTypeKey,

    p.payment_value,

    p.payment_installments,

    1 AS PaymentCount

FROM stg.olist_order_payments p

INNER JOIN stg.olist_orders o
    ON p.order_id = o.order_id

INNER JOIN dw.DimCustomer c
    ON o.customer_id = c.CustomerID

INNER JOIN dw.DimPaymentType pt
    ON p.payment_type = pt.PaymentType;
GO


/* =========================================================
   4. VERIFY FACT ROW COUNTS
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