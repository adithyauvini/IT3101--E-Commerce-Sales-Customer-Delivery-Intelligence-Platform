USE OlistDWBI;
GO


/* =========================================================
   1. ORDER DATE RANGE
   ========================================================= */

SELECT
    MIN(order_purchase_timestamp) AS MinPurchaseDate,
    MAX(order_purchase_timestamp) AS MaxPurchaseDate,

    MIN(order_delivered_customer_date) AS MinDeliveryDate,
    MAX(order_delivered_customer_date) AS MaxDeliveryDate,

    MIN(order_estimated_delivery_date) AS MinEstimatedDate,
    MAX(order_estimated_delivery_date) AS MaxEstimatedDate
FROM stg.olist_orders;
GO


/* =========================================================
   2. OVERALL DATE RANGE REQUIRED BY DimDate
   ========================================================= */

SELECT
    MIN(DateValue) AS RequiredMinDate,
    MAX(DateValue) AS RequiredMaxDate
FROM
(
    SELECT CAST(order_purchase_timestamp AS DATE) AS DateValue
    FROM stg.olist_orders
    WHERE order_purchase_timestamp IS NOT NULL

    UNION ALL

    SELECT CAST(order_delivered_customer_date AS DATE)
    FROM stg.olist_orders
    WHERE order_delivered_customer_date IS NOT NULL

    UNION ALL

    SELECT CAST(order_estimated_delivery_date AS DATE)
    FROM stg.olist_orders
    WHERE order_estimated_delivery_date IS NOT NULL
) AS d;
GO


/* =========================================================
   3. PAYMENT TYPES
   ========================================================= */

SELECT
    payment_type,
    COUNT(*) AS PaymentRows
FROM stg.olist_order_payments
GROUP BY payment_type
ORDER BY PaymentRows DESC;
GO


/* =========================================================
   4. CUSTOMER ZIP PREFIX COVERAGE IN GEOLOCATION
   ========================================================= */

SELECT
    COUNT(DISTINCT c.customer_zip_code_prefix) AS CustomerZipPrefixes,

    COUNT(DISTINCT CASE
        WHEN g.geolocation_zip_code_prefix IS NOT NULL
        THEN c.customer_zip_code_prefix
    END) AS MatchedZipPrefixes,

    COUNT(DISTINCT CASE
        WHEN g.geolocation_zip_code_prefix IS NULL
        THEN c.customer_zip_code_prefix
    END) AS MissingZipPrefixes
FROM stg.olist_customers AS c
LEFT JOIN
(
    SELECT DISTINCT geolocation_zip_code_prefix
    FROM stg.olist_geolocation
) AS g
    ON c.customer_zip_code_prefix =
       g.geolocation_zip_code_prefix;
GO


/* =========================================================
   5. SELLER ZIP PREFIX COVERAGE IN GEOLOCATION
   ========================================================= */

SELECT
    COUNT(DISTINCT s.seller_zip_code_prefix) AS SellerZipPrefixes,

    COUNT(DISTINCT CASE
        WHEN g.geolocation_zip_code_prefix IS NOT NULL
        THEN s.seller_zip_code_prefix
    END) AS MatchedZipPrefixes,

    COUNT(DISTINCT CASE
        WHEN g.geolocation_zip_code_prefix IS NULL
        THEN s.seller_zip_code_prefix
    END) AS MissingZipPrefixes
FROM stg.olist_sellers AS s
LEFT JOIN
(
    SELECT DISTINCT geolocation_zip_code_prefix
    FROM stg.olist_geolocation
) AS g
    ON s.seller_zip_code_prefix =
       g.geolocation_zip_code_prefix;
GO


/* =========================================================
   6. CUSTOMER COUNTS
   ========================================================= */

SELECT
    COUNT(*) AS CustomerRows,
    COUNT(DISTINCT customer_id) AS DistinctCustomerIDs,
    COUNT(DISTINCT customer_unique_id) AS DistinctUniqueCustomers
FROM stg.olist_customers;
GO


/* =========================================================
   7. CATEGORY COUNTS
   ========================================================= */

SELECT
    COUNT(DISTINCT product_category_name) AS PortugueseCategories
FROM stg.olist_products
WHERE product_category_name IS NOT NULL;
GO