/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
03_load_raw_data.sql

Purpose:
Loads the nine Olist CSV source files into the RAW schema.

Note:
The SQL Server service must have read permission on:
C:\DWBI\OlistRaw
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   RESET RAW TABLES
   ========================================================= */

TRUNCATE TABLE raw.olist_customers;
TRUNCATE TABLE raw.olist_geolocation;
TRUNCATE TABLE raw.olist_orders;
TRUNCATE TABLE raw.olist_order_items;
TRUNCATE TABLE raw.olist_order_payments;
TRUNCATE TABLE raw.olist_order_reviews;
TRUNCATE TABLE raw.olist_products;
TRUNCATE TABLE raw.olist_sellers;
TRUNCATE TABLE raw.product_category_name_translation;
GO


/* =========================================================
   CUSTOMERS
   ========================================================= */

BULK INSERT raw.olist_customers
FROM 'C:\DWBI\OlistRaw\olist_customers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   GEOLOCATION
   ========================================================= */

BULK INSERT raw.olist_geolocation
FROM 'C:\DWBI\OlistRaw\olist_geolocation_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   ORDERS
   ========================================================= */

BULK INSERT raw.olist_orders
FROM 'C:\DWBI\OlistRaw\olist_orders_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   ORDER ITEMS
   ========================================================= */

BULK INSERT raw.olist_order_items
FROM 'C:\DWBI\OlistRaw\olist_order_items_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   PAYMENTS
   ========================================================= */

BULK INSERT raw.olist_order_payments
FROM 'C:\DWBI\OlistRaw\olist_order_payments_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   REVIEWS
   ========================================================= */

BULK INSERT raw.olist_order_reviews
FROM 'C:\DWBI\OlistRaw\olist_order_reviews_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   PRODUCTS
   ========================================================= */

BULK INSERT raw.olist_products
FROM 'C:\DWBI\OlistRaw\olist_products_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   SELLERS
   ========================================================= */

BULK INSERT raw.olist_sellers
FROM 'C:\DWBI\OlistRaw\olist_sellers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   CATEGORY TRANSLATION
   ========================================================= */

BULK INSERT raw.product_category_name_translation
FROM 'C:\DWBI\OlistRaw\product_category_name_translation.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   VERIFY RAW ROW COUNTS
   ========================================================= */

SELECT 'Customers' AS Dataset, COUNT(*) AS TotalRows
FROM raw.olist_customers

UNION ALL
SELECT 'Geolocation', COUNT(*)
FROM raw.olist_geolocation

UNION ALL
SELECT 'Orders', COUNT(*)
FROM raw.olist_orders

UNION ALL
SELECT 'Order Items', COUNT(*)
FROM raw.olist_order_items

UNION ALL
SELECT 'Payments', COUNT(*)
FROM raw.olist_order_payments

UNION ALL
SELECT 'Reviews', COUNT(*)
FROM raw.olist_order_reviews

UNION ALL
SELECT 'Products', COUNT(*)
FROM raw.olist_products

UNION ALL
SELECT 'Sellers', COUNT(*)
FROM raw.olist_sellers

UNION ALL
SELECT 'Category Translation', COUNT(*)
FROM raw.product_category_name_translation;
GO