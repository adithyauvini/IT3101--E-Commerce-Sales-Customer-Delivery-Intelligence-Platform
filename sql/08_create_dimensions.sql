/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
08_create_dimensions.sql

Purpose:
Creates the dimension tables for the dimensional warehouse.

Dimensions:
    DimDate
    DimLocation
    DimCustomer
    DimProduct
    DimSeller
    DimPaymentType

Design:
Surrogate keys are used to separate the warehouse from
operational natural keys.

DimCustomer and DimSeller reference DimLocation so a common
geographic definition can be reused.
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. DIM DATE
   ========================================================= */

IF OBJECT_ID('dw.DimDate', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimDate
    (
        DateKey             INT          NOT NULL,
        FullDate            DATE         NULL,

        DayOfMonth          TINYINT      NULL,
        DayName             VARCHAR(20)  NULL,

        MonthNumber         TINYINT      NULL,
        MonthName           VARCHAR(20)  NULL,

        QuarterNumber       TINYINT      NULL,
        QuarterName         VARCHAR(10)  NULL,

        YearNumber          SMALLINT     NULL,

        YearMonthKey        INT          NULL,
        YearMonthLabel      VARCHAR(7)   NULL,

        CONSTRAINT PK_DimDate
            PRIMARY KEY (DateKey),

        CONSTRAINT UQ_DimDate_FullDate
            UNIQUE (FullDate)
    );

    PRINT 'Created dw.DimDate';
END;
GO


/* =========================================================
   2. DIM LOCATION
   ========================================================= */

IF OBJECT_ID('dw.DimLocation', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimLocation
    (
        LocationKey      INT IDENTITY(1,1) NOT NULL,

        ZipCodePrefix    INT           NOT NULL,

        City             NVARCHAR(255) NULL,
        State            VARCHAR(2)    NULL,

        Latitude         DECIMAL(12,8) NULL,
        Longitude        DECIMAL(12,8) NULL,

        HasGeolocation   BIT           NOT NULL,

        CONSTRAINT PK_DimLocation
            PRIMARY KEY (LocationKey),

        CONSTRAINT UQ_DimLocation_ZipCodePrefix
            UNIQUE (ZipCodePrefix)
    );

    PRINT 'Created dw.DimLocation';
END;
GO


/* =========================================================
   3. DIM CUSTOMER
   ========================================================= */

IF OBJECT_ID('dw.DimCustomer', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimCustomer
    (
        CustomerKey       INT IDENTITY(1,1) NOT NULL,

        CustomerID        VARCHAR(32) NOT NULL,
        CustomerUniqueID  VARCHAR(32) NOT NULL,

        LocationKey       INT NOT NULL,

        CONSTRAINT PK_DimCustomer
            PRIMARY KEY (CustomerKey),

        CONSTRAINT UQ_DimCustomer_CustomerID
            UNIQUE (CustomerID),

        CONSTRAINT FK_DimCustomer_DimLocation
            FOREIGN KEY (LocationKey)
            REFERENCES dw.DimLocation(LocationKey)
    );

    PRINT 'Created dw.DimCustomer';
END;
GO


/* =========================================================
   4. DIM PRODUCT
   ========================================================= */

IF OBJECT_ID('dw.DimProduct', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimProduct
    (
        ProductKey                 INT IDENTITY(1,1) NOT NULL,

        ProductID                  VARCHAR(32) NOT NULL,

        ProductCategoryName        NVARCHAR(255) NULL,
        ProductCategoryEnglish     NVARCHAR(255) NULL,

        ProductNameLength          INT NULL,
        ProductDescriptionLength   INT NULL,
        ProductPhotosQty           INT NULL,

        ProductWeightG             DECIMAL(18,2) NULL,
        ProductLengthCM            DECIMAL(18,2) NULL,
        ProductHeightCM            DECIMAL(18,2) NULL,
        ProductWidthCM             DECIMAL(18,2) NULL,

        CONSTRAINT PK_DimProduct
            PRIMARY KEY (ProductKey),

        CONSTRAINT UQ_DimProduct_ProductID
            UNIQUE (ProductID)
    );

    PRINT 'Created dw.DimProduct';
END;
GO


/* =========================================================
   5. DIM SELLER
   ========================================================= */

IF OBJECT_ID('dw.DimSeller', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimSeller
    (
        SellerKey      INT IDENTITY(1,1) NOT NULL,

        SellerID       VARCHAR(32) NOT NULL,

        LocationKey    INT NOT NULL,

        CONSTRAINT PK_DimSeller
            PRIMARY KEY (SellerKey),

        CONSTRAINT UQ_DimSeller_SellerID
            UNIQUE (SellerID),

        CONSTRAINT FK_DimSeller_DimLocation
            FOREIGN KEY (LocationKey)
            REFERENCES dw.DimLocation(LocationKey)
    );

    PRINT 'Created dw.DimSeller';
END;
GO


/* =========================================================
   6. DIM PAYMENT TYPE
   ========================================================= */

IF OBJECT_ID('dw.DimPaymentType', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimPaymentType
    (
        PaymentTypeKey INT IDENTITY(1,1) NOT NULL,

        PaymentType    VARCHAR(50) NOT NULL,

        CONSTRAINT PK_DimPaymentType
            PRIMARY KEY (PaymentTypeKey),

        CONSTRAINT UQ_DimPaymentType_PaymentType
            UNIQUE (PaymentType)
    );

    PRINT 'Created dw.DimPaymentType';
END;
GO


/* =========================================================
   7. VERIFY DIMENSION TABLES
   ========================================================= */

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'dw'
  AND t.name LIKE 'Dim%'
ORDER BY t.name;
GO