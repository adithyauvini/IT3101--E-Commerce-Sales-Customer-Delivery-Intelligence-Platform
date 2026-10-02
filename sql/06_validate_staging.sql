/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
06_validate_staging.sql

Purpose:
Validates the staging layer after cleansing and type
conversion.

Checks:
- Required business keys
- Duplicate business keys
- Expected NULL patterns
- Review-score validity
- Source relationship anomalies
- Translation gaps
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. REQUIRED KEY NULL CHECKS
   Expected: all 0
   ========================================================= */

SELECT
    'Customers - customer_id NULL' AS CheckName,
    COUNT(*) AS IssueRows
FROM stg.olist_customers
WHERE customer_id IS NULL

UNION ALL

SELECT
    'Customers - customer_unique_id NULL',
    COUNT(*)
FROM stg.olist_customers
WHERE customer_unique_id IS NULL

UNION ALL

SELECT
    'Orders - order_id NULL',
    COUNT(*)
FROM stg.olist_orders
WHERE order_id IS NULL

UNION ALL

SELECT
    'Order Items - key NULL',
    COUNT(*)
FROM stg.olist_order_items
WHERE order_id IS NULL
   OR order_item_id IS NULL

UNION ALL

SELECT
    'Payments - key NULL',
    COUNT(*)
FROM stg.olist_order_payments
WHERE order_id IS NULL
   OR payment_sequential IS NULL

UNION ALL

SELECT
    'Reviews - composite key NULL',
    COUNT(*)
FROM stg.olist_order_reviews
WHERE review_id IS NULL
   OR order_id IS NULL

UNION ALL

SELECT
    'Products - product_id NULL',
    COUNT(*)
FROM stg.olist_products
WHERE product_id IS NULL

UNION ALL

SELECT
    'Sellers - seller_id NULL',
    COUNT(*)
FROM stg.olist_sellers
WHERE seller_id IS NULL;
GO


/* =========================================================
   2. DUPLICATE KEY CHECKS
   ========================================================= */

SELECT
    'Customer ID duplicate groups' AS CheckName,
    COUNT(*) AS IssueGroups
FROM
(
    SELECT customer_id
    FROM stg.olist_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'Order ID duplicate groups',
    COUNT(*)
FROM
(
    SELECT order_id
    FROM stg.olist_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'Order Item composite duplicate groups',
    COUNT(*)
FROM
(
    SELECT order_id, order_item_id
    FROM stg.olist_order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'Payment composite duplicate groups',
    COUNT(*)
FROM
(
    SELECT order_id, payment_sequential
    FROM stg.olist_order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'Review composite duplicate groups',
    COUNT(*)
FROM
(
    SELECT review_id, order_id
    FROM stg.olist_order_reviews
    GROUP BY review_id, order_id
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'Product ID duplicate groups',
    COUNT(*)
FROM
(
    SELECT product_id
    FROM stg.olist_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS x

UNION ALL

SELECT
    'Seller ID duplicate groups',
    COUNT(*)
FROM
(
    SELECT seller_id
    FROM stg.olist_sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) AS x;
GO


/* =========================================================
   3. KNOWN ORDER NULL PATTERN
   Expected from Python profiling:
   Approved: 160
   Carrier Delivery: 1,783
   Customer Delivery: 2,965
   ========================================================= */

SELECT
    COUNT(*) AS TotalOrders,

    SUM(
        CASE
            WHEN order_approved_at IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingApproval,

    SUM(
        CASE
            WHEN order_delivered_carrier_date IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingCarrierDelivery,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingCustomerDelivery,

    SUM(
        CASE
            WHEN order_purchase_timestamp IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingPurchaseTimestamp,

    SUM(
        CASE
            WHEN order_estimated_delivery_date IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingEstimatedDelivery

FROM stg.olist_orders;
GO


/* =========================================================
   4. PRODUCT NULL PATTERN

   Expected:
   610 missing category/name/description/photos
   2 missing physical measurements
   ========================================================= */

SELECT
    COUNT(*) AS TotalProducts,

    SUM(
        CASE WHEN product_category_name IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingCategory,

    SUM(
        CASE WHEN product_name_lenght IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingNameLength,

    SUM(
        CASE WHEN product_description_lenght IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingDescriptionLength,

    SUM(
        CASE WHEN product_photos_qty IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingPhotos,

    SUM(
        CASE WHEN product_weight_g IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingWeight,

    SUM(
        CASE WHEN product_length_cm IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingLength,

    SUM(
        CASE WHEN product_height_cm IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingHeight,

    SUM(
        CASE WHEN product_width_cm IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingWidth

FROM stg.olist_products;
GO


/* =========================================================
   5. REVIEW SCORE DOMAIN CHECK
   Expected issue rows: 0
   Valid range: 1 to 5
   ========================================================= */

SELECT
    COUNT(*) AS InvalidReviewScores
FROM stg.olist_order_reviews
WHERE review_score IS NULL
   OR review_score < 1
   OR review_score > 5;
GO


/* =========================================================
   6. REVIEW CARDINALITY CHECK
   Expected:
   547 orders with multiple reviews
   Maximum reviews per order = 3
   ========================================================= */

WITH ReviewCounts AS
(
    SELECT
        order_id,
        COUNT(*) AS ReviewCount
    FROM stg.olist_order_reviews
    GROUP BY order_id
)
SELECT
    SUM(
        CASE WHEN ReviewCount > 1
        THEN 1 ELSE 0 END
    ) AS OrdersWithMultipleReviews,

    MAX(ReviewCount) AS MaximumReviewsPerOrder
FROM ReviewCounts;
GO


/* =========================================================
   7. FRACTIONAL REVIEW AVERAGE CHECK

   This proves FactOrder ReviewScore must support decimals.
   Expected: 123 orders
   ========================================================= */

WITH ReviewAverage AS
(
    SELECT
        order_id,
        AVG(
            CAST(review_score AS DECIMAL(10,4))
        ) AS AverageReviewScore
    FROM stg.olist_order_reviews
    GROUP BY order_id
)
SELECT
    COUNT(*) AS OrdersWithFractionalReviewAverage
FROM ReviewAverage
WHERE AverageReviewScore
      <> FLOOR(AverageReviewScore);
GO


/* =========================================================
   8. ORDER STATUS DISTRIBUTION
   ========================================================= */

SELECT
    order_status,
    COUNT(*) AS TotalOrders
FROM stg.olist_orders
GROUP BY order_status
ORDER BY TotalOrders DESC;
GO


/* =========================================================
   9. DELIVERED ORDERS MISSING DELIVERY DATE

   Known source anomaly.
   Expected: 8
   ========================================================= */

SELECT
    COUNT(*) AS DeliveredWithoutCustomerDeliveryDate
FROM stg.olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;
GO


/* =========================================================
   10. ORDERS WITHOUT PAYMENT

   Expected: 1
   ========================================================= */

SELECT
    COUNT(*) AS OrdersWithoutPayments
FROM stg.olist_orders AS o
LEFT JOIN stg.olist_order_payments AS p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;
GO


/* =========================================================
   11. CATEGORY TRANSLATION GAPS

   Expected:
   2 categories
   13 products
   ========================================================= */

SELECT
    p.product_category_name,
    COUNT(*) AS ProductCount
FROM stg.olist_products AS p
LEFT JOIN stg.product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY ProductCount DESC;
GO


/* =========================================================
   12. GEOLOCATION BASIC VALIDATION
   ========================================================= */

SELECT
    COUNT(*) AS TotalGeoRows,

    SUM(
        CASE
            WHEN geolocation_zip_code_prefix IS NULL
              OR geolocation_lat IS NULL
              OR geolocation_lng IS NULL
            THEN 1
            ELSE 0
        END
    ) AS InvalidGeoRows,

    COUNT(
        DISTINCT geolocation_zip_code_prefix
    ) AS DistinctZipPrefixes

FROM stg.olist_geolocation;
GO