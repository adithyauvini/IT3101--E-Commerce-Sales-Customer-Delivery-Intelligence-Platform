/*
============================================================
Script:
02_create_raw_tables.sql

Purpose:
Creates raw landing tables for the nine Olist CSV sources.

Design:
Source values are stored as VARCHAR because the raw layer
preserves incoming data before cleansing and conversion.

RawRowID is warehouse load metadata and does not replace
the original source business keys.
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   CUSTOMERS
   ========================================================= */

IF OBJECT_ID('raw.olist_customers', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_customers
    (

        customer_id                VARCHAR(100) NULL,
        customer_unique_id         VARCHAR(100) NULL,
        customer_zip_code_prefix   VARCHAR(50)  NULL,
        customer_city              VARCHAR(255) NULL,
        customer_state             VARCHAR(50)  NULL
    );

    PRINT 'Created raw.olist_customers';
END;
GO


/* =========================================================
   GEOLOCATION
   ========================================================= */

IF OBJECT_ID('raw.olist_geolocation', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_geolocation
    (

        geolocation_zip_code_prefix VARCHAR(50)  NULL,
        geolocation_lat             VARCHAR(100) NULL,
        geolocation_lng             VARCHAR(100) NULL,
        geolocation_city            VARCHAR(255) NULL,
        geolocation_state           VARCHAR(50)  NULL
    );

    PRINT 'Created raw.olist_geolocation';
END;
GO


/* =========================================================
   ORDERS
   ========================================================= */

IF OBJECT_ID('raw.olist_orders', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_orders
    (

        order_id                       VARCHAR(100) NULL,
        customer_id                    VARCHAR(100) NULL,
        order_status                   VARCHAR(50)  NULL,
        order_purchase_timestamp       VARCHAR(100) NULL,
        order_approved_at              VARCHAR(100) NULL,
        order_delivered_carrier_date   VARCHAR(100) NULL,
        order_delivered_customer_date  VARCHAR(100) NULL,
        order_estimated_delivery_date  VARCHAR(100) NULL
    );

    PRINT 'Created raw.olist_orders';
END;
GO


/* =========================================================
   ORDER ITEMS
   ========================================================= */

IF OBJECT_ID('raw.olist_order_items', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_order_items
    (

        order_id             VARCHAR(100) NULL,
        order_item_id        VARCHAR(50)  NULL,
        product_id           VARCHAR(100) NULL,
        seller_id            VARCHAR(100) NULL,
        shipping_limit_date  VARCHAR(100) NULL,
        price                 VARCHAR(100) NULL,
        freight_value         VARCHAR(100) NULL
    );

    PRINT 'Created raw.olist_order_items';
END;
GO


/* =========================================================
   ORDER PAYMENTS
   ========================================================= */

IF OBJECT_ID('raw.olist_order_payments', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_order_payments
    (

        order_id               VARCHAR(100) NULL,
        payment_sequential     VARCHAR(50)  NULL,
        payment_type           VARCHAR(100) NULL,
        payment_installments   VARCHAR(50)  NULL,
        payment_value          VARCHAR(100) NULL
    );

    PRINT 'Created raw.olist_order_payments';
END;
GO


/* =========================================================
   ORDER REVIEWS
   ========================================================= */

IF OBJECT_ID('raw.olist_order_reviews', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_order_reviews
    (

        review_id                VARCHAR(100)  NULL,
        order_id                 VARCHAR(100)  NULL,
        review_score             VARCHAR(50)   NULL,
        review_comment_title     VARCHAR(MAX)  NULL,
        review_comment_message   VARCHAR(MAX)  NULL,
        review_creation_date     VARCHAR(100)  NULL,
        review_answer_timestamp  VARCHAR(100)  NULL
    );

    PRINT 'Created raw.olist_order_reviews';
END;
GO


/* =========================================================
   PRODUCTS
   ========================================================= */

IF OBJECT_ID('raw.olist_products', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_products
    (

        product_id                  VARCHAR(100) NULL,
        product_category_name       VARCHAR(255) NULL,
        product_name_lenght         VARCHAR(50)  NULL,
        product_description_lenght  VARCHAR(50)  NULL,
        product_photos_qty          VARCHAR(50)  NULL,
        product_weight_g            VARCHAR(50)  NULL,
        product_length_cm           VARCHAR(50)  NULL,
        product_height_cm           VARCHAR(50)  NULL,
        product_width_cm            VARCHAR(50)  NULL
    );

    PRINT 'Created raw.olist_products';
END;
GO


/* =========================================================
   SELLERS
   ========================================================= */

IF OBJECT_ID('raw.olist_sellers', 'U') IS NULL
BEGIN
    CREATE TABLE raw.olist_sellers
    (

        seller_id               VARCHAR(100) NULL,
        seller_zip_code_prefix  VARCHAR(50)  NULL,
        seller_city             VARCHAR(255) NULL,
        seller_state            VARCHAR(50)  NULL
    );

    PRINT 'Created raw.olist_sellers';
END;
GO


/* =========================================================
   PRODUCT CATEGORY TRANSLATION
   ========================================================= */

IF OBJECT_ID('raw.product_category_name_translation', 'U') IS NULL
BEGIN
    CREATE TABLE raw.product_category_name_translation
    (

        product_category_name          VARCHAR(255) NULL,
        product_category_name_english  VARCHAR(255) NULL
    );

    PRINT 'Created raw.product_category_name_translation';
END;
GO


/* =========================================================
   VERIFY RAW TABLES
   ========================================================= */

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'raw'
ORDER BY t.name;
GO

