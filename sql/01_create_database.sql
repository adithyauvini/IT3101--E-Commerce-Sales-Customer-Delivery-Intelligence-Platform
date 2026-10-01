/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
01_create_database.sql

Purpose:
Creates the OlistDWBI database and logical schemas used by
the Data Warehouse and Business Intelligence solution.

Schemas:
    raw  - Original source data
    stg  - Cleaned and typed staging data
    dw   - Dimensional warehouse
    mart - Analytical views for Power BI
============================================================
*/

USE master;
GO


/* =========================================================
   1. CREATE DATABASE
   ========================================================= */

IF DB_ID(N'OlistDWBI') IS NULL
BEGIN
    CREATE DATABASE OlistDWBI;

    PRINT 'Database OlistDWBI created successfully.';
END
ELSE
BEGIN
    PRINT 'Database OlistDWBI already exists.';
END;
GO


USE OlistDWBI;
GO


/* =========================================================
   2. CREATE SCHEMAS
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'raw'
)
BEGIN
    EXEC('CREATE SCHEMA raw AUTHORIZATION dbo');

    PRINT 'Schema raw created.';
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg AUTHORIZATION dbo');

    PRINT 'Schema stg created.';
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dw'
)
BEGIN
    EXEC('CREATE SCHEMA dw AUTHORIZATION dbo');

    PRINT 'Schema dw created.';
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'mart'
)
BEGIN
    EXEC('CREATE SCHEMA mart AUTHORIZATION dbo');

    PRINT 'Schema mart created.';
END;
GO


/* =========================================================
   3. VERIFY DATABASE AND SCHEMAS
   ========================================================= */

SELECT
    DB_NAME() AS CurrentDatabase;


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