/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
05_load_staging.sql

Purpose:
Transforms raw Olist source data into typed and cleaned
staging tables.

Main transformations:
- Trim text values
- Convert empty strings to NULL
- Convert dates using TRY_CONVERT
- Convert numerical values
- Standardise state codes
- Preserve source-level grain
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. RESET STAGING TABLES
   ========================================================= */

TRUNCATE TABLE stg.olist_customers;
TRUNCATE TABLE stg.olist_geolocation;
TRUNCATE TABLE stg.olist_orders;
TRUNCATE TABLE stg.olist_order_items;
TRUNCATE TABLE stg.olist_order_payments;
TRUNCATE TABLE stg.olist_order_reviews;
TRUNCATE TABLE stg.olist_products;
TRUNCATE TABLE stg.olist_sellers;
TRUNCATE TABLE stg.product_category_name_translation;
GO


/* =========================================================
   2. CUSTOMERS
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
    NULLIF(LTRIM(RTRIM(customer_id)), ''),
    NULLIF(LTRIM(RTRIM(customer_unique_id)), ''),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), '')
    ),

    NULLIF(LTRIM(RTRIM(customer_city)), ''),

    UPPER(
        NULLIF(LTRIM(RTRIM(customer_state)), '')
    )
FROM raw.olist_customers;
GO


/* =========================================================
   3. GEOLOCATION
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
    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(geolocation_zip_code_prefix)), '')
    ),

    TRY_CONVERT(
        DECIMAL(12,8),
        NULLIF(LTRIM(RTRIM(geolocation_lat)), '')
    ),

    TRY_CONVERT(
        DECIMAL(12,8),
        NULLIF(LTRIM(RTRIM(geolocation_lng)), '')
    ),

    NULLIF(LTRIM(RTRIM(geolocation_city)), ''),

    UPPER(
        NULLIF(LTRIM(RTRIM(geolocation_state)), '')
    )

FROM raw.olist_geolocation;
GO


/* =========================================================
   4. ORDERS
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
    NULLIF(LTRIM(RTRIM(order_id)), ''),
    NULLIF(LTRIM(RTRIM(customer_id)), ''),
    LOWER(NULLIF(LTRIM(RTRIM(order_status)), '')),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), ''),
        120
    ),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_approved_at)), ''),
        120
    ),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), ''),
        120
    ),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''),
        120
    ),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), ''),
        120
    )

FROM raw.olist_orders;
GO


/* =========================================================
   5. ORDER ITEMS
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
    NULLIF(LTRIM(RTRIM(order_id)), ''),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(order_item_id)), '')
    ),

    NULLIF(LTRIM(RTRIM(product_id)), ''),

    NULLIF(LTRIM(RTRIM(seller_id)), ''),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(shipping_limit_date)), ''),
        120
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(price)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(freight_value)), '')
    )

FROM raw.olist_order_items;
GO


/* =========================================================
   6. PAYMENTS
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
    NULLIF(LTRIM(RTRIM(order_id)), ''),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(payment_sequential)), '')
    ),

    LOWER(
        NULLIF(LTRIM(RTRIM(payment_type)), '')
    ),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(payment_installments)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(payment_value)), '')
    )

FROM raw.olist_order_payments;
GO


/* =========================================================
   7. REVIEWS
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
    NULLIF(LTRIM(RTRIM(review_id)), ''),

    NULLIF(LTRIM(RTRIM(order_id)), ''),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(review_score)), '')
    ),

    NULLIF(LTRIM(RTRIM(review_comment_title)), ''),

    NULLIF(LTRIM(RTRIM(review_comment_message)), ''),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(review_creation_date)), ''),
        120
    ),

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(review_answer_timestamp)), ''),
        120
    )

FROM raw.olist_order_reviews;
GO


/* =========================================================
   8. PRODUCTS
   ========================================================= */

INSERT INTO stg.olist_products
(
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    NULLIF(LTRIM(RTRIM(product_id)), ''),

    NULLIF(
        LTRIM(RTRIM(product_category_name)),
        ''
    ),

    /*
       These fields may appear as values such as 40.0 in
       the source CSV. Convert first to DECIMAL and then INT.
    */
    TRY_CONVERT(
        INT,
        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(LTRIM(RTRIM(product_name_lenght)), '')
        )
    ),

    TRY_CONVERT(
        INT,
        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(LTRIM(RTRIM(product_description_lenght)), '')
        )
    ),

    TRY_CONVERT(
        INT,
        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(LTRIM(RTRIM(product_photos_qty)), '')
        )
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(product_weight_g)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(product_length_cm)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(product_height_cm)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(product_width_cm)), '')
    )

FROM raw.olist_products;
GO


/* =========================================================
   9. SELLERS
   ========================================================= */

INSERT INTO stg.olist_sellers
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    NULLIF(LTRIM(RTRIM(seller_id)), ''),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), '')
    ),

    NULLIF(LTRIM(RTRIM(seller_city)), ''),

    UPPER(
        NULLIF(LTRIM(RTRIM(seller_state)), '')
    )

FROM raw.olist_sellers;
GO


/* =========================================================
   10. CATEGORY TRANSLATION
   ========================================================= */

INSERT INTO stg.product_category_name_translation
(
    product_category_name,
    product_category_name_english
)
SELECT
    NULLIF(
        LTRIM(RTRIM(product_category_name)),
        ''
    ),

    NULLIF(
        LTRIM(RTRIM(product_category_name_english)),
        ''
    )

FROM raw.product_category_name_translation;
GO


/* =========================================================
   11. VERIFY RAW VS STAGING COUNTS
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