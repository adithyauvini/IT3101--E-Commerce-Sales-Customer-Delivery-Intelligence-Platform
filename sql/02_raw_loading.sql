/* =========================================================
   FILE: 02_raw_loading.sql
   PURPOSE:
   Load raw Olist CSV files into RAW schema tables
   ========================================================= */


USE OlistDWBI;
GO


/* =========================================================
   1. LOAD CUSTOMERS
   ========================================================= */

BULK INSERT raw.olist_customers
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_customers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   2. LOAD GEOLOCATION
   ========================================================= */

BULK INSERT raw.olist_geolocation
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_geolocation_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   3. LOAD ORDERS
   ========================================================= */

BULK INSERT raw.olist_orders
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_orders_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   4. LOAD ORDER ITEMS
   ========================================================= */

BULK INSERT raw.olist_order_items
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_order_items_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   5. LOAD PAYMENTS
   ========================================================= */

BULK INSERT raw.olist_order_payments
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_order_payments_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   6. LOAD REVIEWS
   ========================================================= */

BULK INSERT raw.olist_order_reviews
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_order_reviews_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   7. LOAD PRODUCTS
   ========================================================= */

BULK INSERT raw.olist_products
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_products_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   8. LOAD SELLERS
   ========================================================= */

BULK INSERT raw.olist_sellers
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\olist_sellers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   9. LOAD PRODUCT CATEGORY TRANSLATION
   ========================================================= */

BULK INSERT raw.product_category_name_translation
FROM 'C:\Users\User\Desktop\DWBI\Project\data\raw\product_category_name_translation.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO


/* =========================================================
   10. VERIFY RAW TABLE ROW COUNTS
   ========================================================= */

SELECT
    'raw.olist_customers' AS TableName,
    COUNT(*) AS TotalRows
FROM raw.olist_customers

UNION ALL

SELECT
    'raw.olist_geolocation',
    COUNT(*)
FROM raw.olist_geolocation

UNION ALL

SELECT
    'raw.olist_orders',
    COUNT(*)
FROM raw.olist_orders

UNION ALL

SELECT
    'raw.olist_order_items',
    COUNT(*)
FROM raw.olist_order_items

UNION ALL

SELECT
    'raw.olist_order_payments',
    COUNT(*)
FROM raw.olist_order_payments

UNION ALL

SELECT
    'raw.olist_order_reviews',
    COUNT(*)
FROM raw.olist_order_reviews

UNION ALL

SELECT
    'raw.olist_products',
    COUNT(*)
FROM raw.olist_products

UNION ALL

SELECT
    'raw.olist_sellers',
    COUNT(*)
FROM raw.olist_sellers

UNION ALL

SELECT
    'raw.product_category_name_translation',
    COUNT(*)
FROM raw.product_category_name_translation

ORDER BY TableName;
GO