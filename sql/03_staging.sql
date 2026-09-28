/* =========================================================
   FILE: 03_staging.sql
   PURPOSE:
   Clean and transform RAW data into STAGING tables
   ========================================================= */


USE OlistDWBI;
GO


/* =========================================================
   1. STAGE CUSTOMERS
   ========================================================= */

INSERT INTO stg.olist_customers
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    LTRIM(RTRIM(customer_id)),
    LTRIM(RTRIM(customer_unique_id)),
    TRY_CONVERT(INT, customer_zip_code_prefix),
    LTRIM(RTRIM(customer_city)),
    LTRIM(RTRIM(customer_state))
FROM raw.olist_customers;
GO


/* =========================================================
   2. STAGE GEOLOCATION
   ========================================================= */

INSERT INTO stg.olist_geolocation
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT
    TRY_CONVERT(INT, geolocation_zip_code_prefix),
    TRY_CONVERT(DECIMAL(10, 8), geolocation_lat),
    TRY_CONVERT(DECIMAL(11, 8), geolocation_lng),
    LTRIM(RTRIM(geolocation_city)),
    LTRIM(RTRIM(geolocation_state))
FROM raw.olist_geolocation;
GO


/* =========================================================
   3. STAGE ORDERS
   ========================================================= */

INSERT INTO stg.olist_orders
(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    LTRIM(RTRIM(order_id)),
    LTRIM(RTRIM(customer_id)),
    LTRIM(RTRIM(order_status)),
    TRY_CONVERT(DATETIME2, order_purchase_timestamp),
    TRY_CONVERT(DATETIME2, order_approved_at),
    TRY_CONVERT(DATETIME2, order_delivered_carrier_date),
    TRY_CONVERT(DATETIME2, order_delivered_customer_date),
    TRY_CONVERT(DATETIME2, order_estimated_delivery_date)
FROM raw.olist_orders;
GO


/* =========================================================
   4. STAGE ORDER ITEMS
   ========================================================= */

INSERT INTO stg.olist_order_items
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    LTRIM(RTRIM(order_id)),
    TRY_CONVERT(INT, order_item_id),
    LTRIM(RTRIM(product_id)),
    LTRIM(RTRIM(seller_id)),
    TRY_CONVERT(DATETIME2, shipping_limit_date),
    TRY_CONVERT(DECIMAL(18, 2), price),
    TRY_CONVERT(DECIMAL(18, 2), freight_value)
FROM raw.olist_order_items;
GO


/* =========================================================
   5. STAGE ORDER PAYMENTS
   ========================================================= */

INSERT INTO stg.olist_order_payments
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    LTRIM(RTRIM(order_id)),
    TRY_CONVERT(INT, payment_sequential),
    LTRIM(RTRIM(payment_type)),
    TRY_CONVERT(INT, payment_installments),
    TRY_CONVERT(DECIMAL(18, 2), payment_value)
FROM raw.olist_order_payments;
GO


/* =========================================================
   6. STAGE ORDER REVIEWS
   ========================================================= */

INSERT INTO stg.olist_order_reviews
(
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    LTRIM(RTRIM(review_id)),
    LTRIM(RTRIM(order_id)),
    TRY_CONVERT(INT, review_score),
    LTRIM(RTRIM(review_comment_title)),
    LTRIM(RTRIM(review_comment_message)),
    TRY_CONVERT(DATETIME2, review_creation_date),
    TRY_CONVERT(DATETIME2, review_answer_timestamp)
FROM raw.olist_order_reviews;
GO


/* =========================================================
   7. STAGE PRODUCTS
   ========================================================= */

INSERT INTO stg.olist_products
(
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    LTRIM(RTRIM(product_id)),
    LTRIM(RTRIM(product_category_name)),
    TRY_CONVERT(INT, product_name_length),
    TRY_CONVERT(INT, product_description_length),
    TRY_CONVERT(INT, product_photos_qty),
    TRY_CONVERT(DECIMAL(18, 2), product_weight_g),
    TRY_CONVERT(DECIMAL(18, 2), product_length_cm),
    TRY_CONVERT(DECIMAL(18, 2), product_height_cm),
    TRY_CONVERT(DECIMAL(18, 2), product_width_cm)
FROM raw.olist_products;
GO


/* =========================================================
   8. STAGE SELLERS
   ========================================================= */

INSERT INTO stg.olist_sellers
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    LTRIM(RTRIM(seller_id)),
    TRY_CONVERT(INT, seller_zip_code_prefix),
    LTRIM(RTRIM(seller_city)),
    LTRIM(RTRIM(seller_state))
FROM raw.olist_sellers;
GO


/* =========================================================
   9. STAGE PRODUCT CATEGORY TRANSLATION
   ========================================================= */

INSERT INTO stg.product_category_translation
(
    product_category_name,
    product_category_name_english
)
SELECT
    LTRIM(RTRIM(product_category_name)),
    LTRIM(RTRIM(product_category_name_english))
FROM raw.product_category_name_translation;
GO


/* =========================================================
   10. VERIFY STAGING ROW COUNTS
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