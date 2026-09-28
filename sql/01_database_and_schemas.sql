/* =========================================================
   IT3101 - DATA WAREHOUSING & BUSINESS INTELLIGENCE
   OLIST E-COMMERCE SALES, CUSTOMER & DELIVERY
   INTELLIGENCE PLATFORM

   FILE: 01_database_and_schemas.sql
   PURPOSE:
   Database and schema setup
   ========================================================= */


USE OlistDWBI;
GO


/* =========================================================
   1. VERIFY DATABASE
   ========================================================= */

SELECT
    DB_NAME() AS CurrentDatabase;
GO


/* =========================================================
   2. VERIFY REQUIRED SCHEMAS
   ========================================================= */

SELECT
    name AS SchemaName
FROM sys.schemas
WHERE name IN
(
    'raw',
    'stg',
    'dw',
    'mart'
)
ORDER BY name;
GO


/* =========================================================
   3. VERIFY SCHEMA COUNT
   ========================================================= */

SELECT
    COUNT(*) AS SchemaCount
FROM sys.schemas
WHERE name IN
(
    'raw',
    'stg',
    'dw',
    'mart'
);
GO