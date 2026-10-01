/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
04_create_staging_tables.sql

Purpose:
Creates typed staging tables used to cleanse, standardise,
and convert raw Olist source data before loading the
dimensional warehouse.

Important:
The staging layer preserves the source grain. Business
aggregations such as review averaging and geolocation
consolidation happen later during DW loading.
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   CUSTOMERS
   ========================================================= */

IF OBJECT_ID('stg.olist_customers', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_customers
    (
        customer_id              VARCHAR(32)   NULL,
        customer_unique_id       VARCHAR(32)   NULL,
        customer_zip_code_prefix INT           NULL,
        customer_city            NVARCHAR(255) NULL,
        customer_state           VARCHAR(2)    NULL
    );
END;
GO


/* =========================================================
   GEOLOCATION
   ========================================================= */

IF OBJECT_ID('stg.olist_geolocation', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_geolocation
    (
        geolocation_zip_code_prefix INT           NULL,
        geolocation_lat             DECIMAL(12,8) NULL,
        geolocation_lng             DECIMAL(12,8) NULL,
        geolocation_city            NVARCHAR(255) NULL,
        geolocation_state           VARCHAR(2)    NULL
    );
END;
GO


/* =========================================================
   ORDERS
   ========================================================= */

IF OBJECT_ID('stg.olist_orders', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_orders
    (
        order_id                       VARCHAR(32)  NULL,
        customer_id                    VARCHAR(32)  NULL,
        order_status                   VARCHAR(30)  NULL,

        order_purchase_timestamp       DATETIME2(0) NULL,
        order_approved_at              DATETIME2(0) NULL,
        order_delivered_carrier_date   DATETIME2(0) NULL,
        order_delivered_customer_date  DATETIME2(0) NULL,
        order_estimated_delivery_date  DATETIME2(0) NULL
    );
END;
GO


/* =========================================================
   ORDER ITEMS
   ========================================================= */

IF OBJECT_ID('stg.olist_order_items', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_order_items
    (
        order_id             VARCHAR(32)   NULL,
        order_item_id        INT           NULL,
        product_id           VARCHAR(32)   NULL,
        seller_id            VARCHAR(32)   NULL,
        shipping_limit_date  DATETIME2(0)  NULL,
        price                 DECIMAL(18,2) NULL,
        freight_value         DECIMAL(18,2) NULL
    );
END;
GO


/* =========================================================
   PAYMENTS
   ========================================================= */

IF OBJECT_ID('stg.olist_order_payments', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_order_payments
    (
        order_id             VARCHAR(32)   NULL,
        payment_sequential   INT           NULL,
        payment_type         VARCHAR(50)   NULL,
        payment_installments INT           NULL,
        payment_value        DECIMAL(18,2) NULL
    );
END;
GO


/* =========================================================
   REVIEWS
   ========================================================= */

IF OBJECT_ID('stg.olist_order_reviews', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_order_reviews
    (
        review_id                VARCHAR(32)    NULL,
        order_id                 VARCHAR(32)    NULL,
        review_score             INT            NULL,
        review_comment_title     NVARCHAR(1000) NULL,
        review_comment_message   NVARCHAR(MAX)  NULL,
        review_creation_date     DATETIME2(0)   NULL,
        review_answer_timestamp  DATETIME2(0)   NULL
    );
END;
GO


/* =========================================================
   PRODUCTS
   ========================================================= */

IF OBJECT_ID('stg.olist_products', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_products
    (
        product_id                  VARCHAR(32)   NULL,
        product_category_name       NVARCHAR(255) NULL,

        product_name_lenght         INT           NULL,
        product_description_lenght  INT           NULL,
        product_photos_qty          INT           NULL,

        product_weight_g            DECIMAL(18,2) NULL,
        product_length_cm           DECIMAL(18,2) NULL,
        product_height_cm           DECIMAL(18,2) NULL,
        product_width_cm            DECIMAL(18,2) NULL
    );
END;
GO


/* =========================================================
   SELLERS
   ========================================================= */

IF OBJECT_ID('stg.olist_sellers', 'U') IS NULL
BEGIN
    CREATE TABLE stg.olist_sellers
    (
        seller_id               VARCHAR(32)   NULL,
        seller_zip_code_prefix  INT           NULL,
        seller_city             NVARCHAR(255) NULL,
        seller_state            VARCHAR(2)    NULL
    );
END;
GO


/* =========================================================
   CATEGORY TRANSLATION
   ========================================================= */

IF OBJECT_ID('stg.product_category_name_translation', 'U') IS NULL
BEGIN
    CREATE TABLE stg.product_category_name_translation
    (
        product_category_name          NVARCHAR(255) NULL,
        product_category_name_english  NVARCHAR(255) NULL
    );
END;
GO


/* =========================================================
   VERIFY STAGING TABLES
   ========================================================= */

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'stg'
ORDER BY t.name;
GO