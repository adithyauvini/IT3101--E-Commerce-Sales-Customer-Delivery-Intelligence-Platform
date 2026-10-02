/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
11_load_facts.sql

Purpose:
Loads the three warehouse fact tables from validated
staging data using dimension surrogate-key lookups.

Facts:
    dw.FactOrder
    dw.FactSalesItem
    dw.FactPayment

Grains:
    FactOrder
        One row per order

    FactSalesItem
        One row per order item

    FactPayment
        One row per payment transaction

Derived measures:
    DeliveryDays
    DelayDays
    OnTimeFlag
    ReviewScore
    ItemTotal
============================================================
*/

USE OlistDWBI;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


BEGIN TRY

    BEGIN TRANSACTION;


    /* =====================================================
       1. RESET FACT TABLES
       ===================================================== */

    TRUNCATE TABLE dw.FactOrder;
    TRUNCATE TABLE dw.FactSalesItem;
    TRUNCATE TABLE dw.FactPayment;



    /* =====================================================
       2. LOAD FACT ORDER

       Business process:
       Order lifecycle and delivery performance

       Grain:
       One row per order

       Review handling:
       Multiple reviews belonging to the same order are
       averaged before joining to FactOrder.

       This prevents review rows from changing the
       one-row-per-order fact grain.
       ===================================================== */

    ;WITH ReviewAggregate AS
    (
        SELECT
            order_id,

            CAST
            (
                AVG
                (
                    CAST(
                        review_score
                        AS DECIMAL(10,4)
                    )
                )
                AS DECIMAL(4,2)
            ) AS AverageReviewScore

        FROM stg.olist_order_reviews

        GROUP BY
            order_id
    )

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

        COALESCE(
            c.CustomerKey,
            0
        ) AS CustomerKey,

        purchaseDate.DateKey
            AS PurchaseDateKey,

        deliveryDate.DateKey
            AS DeliveryDateKey,

        estimatedDate.DateKey
            AS EstimatedDeliveryDateKey,

        o.order_status,

        1 AS OrderCount,


        /* -----------------------------------------------
           DeliveryDays

           Number of days between purchase and actual
           customer delivery.

           NULL when delivery date is unavailable.
           ----------------------------------------------- */

        CASE
            WHEN o.order_delivered_customer_date IS NULL
                THEN NULL

            ELSE DATEDIFF
            (
                DAY,
                o.order_purchase_timestamp,
                o.order_delivered_customer_date
            )
        END AS DeliveryDays,


        /* -----------------------------------------------
           DelayDays

           Actual Delivery - Estimated Delivery

           Positive value = late
           Zero           = delivered on estimated date
           Negative value = delivered early

           NULL when actual delivery is unavailable.
           ----------------------------------------------- */

        CASE
            WHEN o.order_delivered_customer_date IS NULL
                THEN NULL

            ELSE DATEDIFF
            (
                DAY,
                o.order_estimated_delivery_date,
                o.order_delivered_customer_date
            )
        END AS DelayDays,


        /* -----------------------------------------------
           OnTimeFlag

           1 = delivered on or before estimated date
           0 = delivered after estimated date
           NULL = actual delivery date unavailable

           Undelivered/cancelled orders are therefore NOT
           incorrectly classified as late.
           ----------------------------------------------- */

        CASE
            WHEN o.order_delivered_customer_date IS NULL
                THEN NULL

            WHEN
                o.order_delivered_customer_date
                <= o.order_estimated_delivery_date
                THEN 1

            ELSE 0

        END AS OnTimeFlag,


        reviews.AverageReviewScore
            AS ReviewScore


    FROM stg.olist_orders AS o


    LEFT JOIN dw.DimCustomer AS c
        ON o.customer_id =
           c.CustomerID


    INNER JOIN dw.DimDate AS purchaseDate
        ON CAST(
               o.order_purchase_timestamp
               AS DATE
           ) =
           purchaseDate.FullDate


    LEFT JOIN dw.DimDate AS deliveryDate
        ON CAST(
               o.order_delivered_customer_date
               AS DATE
           ) =
           deliveryDate.FullDate


    INNER JOIN dw.DimDate AS estimatedDate
        ON CAST(
               o.order_estimated_delivery_date
               AS DATE
           ) =
           estimatedDate.FullDate


    LEFT JOIN ReviewAggregate AS reviews
        ON o.order_id =
           reviews.order_id;



    /* =====================================================
       3. LOAD FACT SALES ITEM

       Business process:
       Product sales

       Grain:
       One row per:
       order_id + order_item_id

       ItemTotal:
       Price + FreightValue
       ===================================================== */

    INSERT INTO dw.FactSalesItem
    (
        OrderID,
        OrderItemID,
        CustomerKey,
        PurchaseDateKey,
        ProductKey,
        SellerKey,
        Price,
        FreightValue,
        ItemTotal,
        ItemCount
    )

    SELECT
        i.order_id,

        i.order_item_id,


        COALESCE(
            customer.CustomerKey,
            0
        ) AS CustomerKey,


        purchaseDate.DateKey
            AS PurchaseDateKey,


        COALESCE(
            product.ProductKey,
            0
        ) AS ProductKey,


        COALESCE(
            seller.SellerKey,
            0
        ) AS SellerKey,


        COALESCE(
            i.price,
            0
        ) AS Price,


        COALESCE(
            i.freight_value,
            0
        ) AS FreightValue,


        COALESCE(
            i.price,
            0
        )
        +
        COALESCE(
            i.freight_value,
            0
        ) AS ItemTotal,


        1 AS ItemCount


    FROM stg.olist_order_items AS i


    INNER JOIN stg.olist_orders AS o
        ON i.order_id =
           o.order_id


    LEFT JOIN dw.DimCustomer AS customer
        ON o.customer_id =
           customer.CustomerID


    INNER JOIN dw.DimDate AS purchaseDate
        ON CAST(
               o.order_purchase_timestamp
               AS DATE
           ) =
           purchaseDate.FullDate


    LEFT JOIN dw.DimProduct AS product
        ON i.product_id =
           product.ProductID


    LEFT JOIN dw.DimSeller AS seller
        ON i.seller_id =
           seller.SellerID;



    /* =====================================================
       4. LOAD FACT PAYMENT

       Business process:
       Payment transactions

       Grain:
       One row per:
       order_id + payment_sequential
       ===================================================== */

    INSERT INTO dw.FactPayment
    (
        OrderID,
        PaymentSequential,
        CustomerKey,
        PurchaseDateKey,
        PaymentTypeKey,
        PaymentInstallments,
        PaymentValue,
        PaymentCount
    )

    SELECT
        p.order_id,

        p.payment_sequential,


        COALESCE(
            customer.CustomerKey,
            0
        ) AS CustomerKey,


        purchaseDate.DateKey
            AS PurchaseDateKey,


        COALESCE(
            paymentType.PaymentTypeKey,
            0
        ) AS PaymentTypeKey,


        COALESCE(
            p.payment_installments,
            0
        ) AS PaymentInstallments,


        COALESCE(
            p.payment_value,
            0
        ) AS PaymentValue,


        1 AS PaymentCount


    FROM stg.olist_order_payments AS p


    INNER JOIN stg.olist_orders AS o
        ON p.order_id =
           o.order_id


    LEFT JOIN dw.DimCustomer AS customer
        ON o.customer_id =
           customer.CustomerID


    INNER JOIN dw.DimDate AS purchaseDate
        ON CAST(
               o.order_purchase_timestamp
               AS DATE
           ) =
           purchaseDate.FullDate


    LEFT JOIN dw.DimPaymentType AS paymentType
        ON p.payment_type =
           paymentType.PaymentType;



    COMMIT TRANSACTION;

    PRINT 'Fact tables loaded successfully.';

END TRY


BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Fact loading failed.';

    THROW;

END CATCH;
GO


/* =========================================================
   5. VERIFY FACT ROW COUNTS

   Expected:

   FactOrder       = 99,441
   FactSalesItem   = 112,650
   FactPayment     = 103,886
   ========================================================= */

SELECT
    'FactOrder' AS FactTable,
    COUNT(*) AS TotalRows
FROM dw.FactOrder

UNION ALL

SELECT
    'FactSalesItem',
    COUNT(*)
FROM dw.FactSalesItem

UNION ALL

SELECT
    'FactPayment',
    COUNT(*)
FROM dw.FactPayment;
GO


/* =========================================================
   6. VERIFY FACT GRAINS

   All IssueGroups should be 0.
   ========================================================= */

SELECT
    'FactOrder duplicate OrderID'
        AS CheckName,

    COUNT(*) AS IssueGroups

FROM
(
    SELECT
        OrderID

    FROM dw.FactOrder

    GROUP BY
        OrderID

    HAVING COUNT(*) > 1

) AS x


UNION ALL


SELECT
    'FactSalesItem duplicate grain',

    COUNT(*)

FROM
(
    SELECT
        OrderID,
        OrderItemID

    FROM dw.FactSalesItem

    GROUP BY
        OrderID,
        OrderItemID

    HAVING COUNT(*) > 1

) AS x


UNION ALL


SELECT
    'FactPayment duplicate grain',

    COUNT(*)

FROM
(
    SELECT
        OrderID,
        PaymentSequential

    FROM dw.FactPayment

    GROUP BY
        OrderID,
        PaymentSequential

    HAVING COUNT(*) > 1

) AS x;
GO


/* =========================================================
   7. VERIFY UNKNOWN DIMENSION KEY USAGE

   Expected:
   0 for all fields with the current dataset.
   ========================================================= */

SELECT
    SUM(
        CASE
            WHEN CustomerKey = 0
                THEN 1
            ELSE 0
        END
    ) AS FactOrderUnknownCustomers

FROM dw.FactOrder;
GO


SELECT
    SUM(
        CASE
            WHEN CustomerKey = 0
                THEN 1
            ELSE 0
        END
    ) AS UnknownCustomers,

    SUM(
        CASE
            WHEN ProductKey = 0
                THEN 1
            ELSE 0
        END
    ) AS UnknownProducts,

    SUM(
        CASE
            WHEN SellerKey = 0
                THEN 1
            ELSE 0
        END
    ) AS UnknownSellers

FROM dw.FactSalesItem;
GO


SELECT
    SUM(
        CASE
            WHEN CustomerKey = 0
                THEN 1
            ELSE 0
        END
    ) AS UnknownCustomers,

    SUM(
        CASE
            WHEN PaymentTypeKey = 0
                THEN 1
            ELSE 0
        END
    ) AS UnknownPaymentTypes

FROM dw.FactPayment;
GO


/* =========================================================
   8. VERIFY DELIVERY NULL HANDLING

   Expected:
   2,965 orders without actual delivery date.

   Therefore:
   DeliveryDateKey NULL = 2,965
   DeliveryDays NULL    = 2,965
   DelayDays NULL       = 2,965
   OnTimeFlag NULL      = 2,965
   ========================================================= */

SELECT
    SUM(
        CASE
            WHEN DeliveryDateKey IS NULL
                THEN 1
            ELSE 0
        END
    ) AS MissingDeliveryDateKey,

    SUM(
        CASE
            WHEN DeliveryDays IS NULL
                THEN 1
            ELSE 0
        END
    ) AS MissingDeliveryDays,

    SUM(
        CASE
            WHEN DelayDays IS NULL
                THEN 1
            ELSE 0
        END
    ) AS MissingDelayDays,

    SUM(
        CASE
            WHEN OnTimeFlag IS NULL
                THEN 1
            ELSE 0
        END
    ) AS MissingOnTimeFlag

FROM dw.FactOrder;
GO


/* =========================================================
   9. VERIFY REVIEW AGGREGATION

   Source:
   98,673 orders represented in reviews.

   Total orders:
   99,441

   Expected FactOrder rows without ReviewScore:
   768

   Fractional averages expected:
   123
   ========================================================= */

SELECT
    SUM(
        CASE
            WHEN ReviewScore IS NULL
                THEN 1
            ELSE 0
        END
    ) AS OrdersWithoutReview,

    SUM(
        CASE
            WHEN ReviewScore IS NOT NULL
             AND ReviewScore <> FLOOR(ReviewScore)
                THEN 1
            ELSE 0
        END
    ) AS OrdersWithFractionalReviewScore

FROM dw.FactOrder;
GO


/* =========================================================
   10. VERIFY ITEM TOTAL CALCULATION

   Expected IssueRows = 0
   ========================================================= */

SELECT
    COUNT(*) AS IncorrectItemTotals

FROM dw.FactSalesItem

WHERE ItemTotal
      <>
      Price + FreightValue;
GO


/* =========================================================
   11. VERIFY SALES TOTALS AGAINST STAGING
   ========================================================= */

SELECT
    (
        SELECT
            SUM(price)
        FROM stg.olist_order_items
    ) AS StagingPriceTotal,

    (
        SELECT
            SUM(Price)
        FROM dw.FactSalesItem
    ) AS FactPriceTotal,

    (
        SELECT
            SUM(freight_value)
        FROM stg.olist_order_items
    ) AS StagingFreightTotal,

    (
        SELECT
            SUM(FreightValue)
        FROM dw.FactSalesItem
    ) AS FactFreightTotal;
GO


/* =========================================================
   12. VERIFY PAYMENT TOTALS AGAINST STAGING
   ========================================================= */

SELECT
    (
        SELECT
            SUM(payment_value)
        FROM stg.olist_order_payments
    ) AS StagingPaymentTotal,

    (
        SELECT
            SUM(PaymentValue)
        FROM dw.FactPayment
    ) AS FactPaymentTotal;
GO


/* =========================================================
   13. SAMPLE FACT ORDER ROWS
   ========================================================= */

SELECT TOP (10)
    *

FROM dw.FactOrder

ORDER BY
    FactOrderKey;
GO


/* =========================================================
   14. SAMPLE FACT SALES ITEM ROWS
   ========================================================= */

SELECT TOP (10)
    *

FROM dw.FactSalesItem

ORDER BY
    FactSalesItemKey;
GO


/* =========================================================
   15. SAMPLE FACT PAYMENT ROWS
   ========================================================= */

SELECT TOP (10)
    *

FROM dw.FactPayment

ORDER BY
    FactPaymentKey;
GO