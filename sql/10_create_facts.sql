/*
============================================================
Project:
E-Commerce Sales, Customer & Delivery Intelligence Platform

Script:
10_create_facts.sql

Purpose:
Creates the three fact tables used by the dimensional
warehouse.

Facts:
    FactOrder
    FactSalesItem
    FactPayment

Grains:
    FactOrder
        One row per order

    FactSalesItem
        One row per order item

    FactPayment
        One row per payment transaction

Important:
Foreign-key constraints are implemented between facts
and dimensions.
============================================================
*/

USE OlistDWBI;
GO


/* =========================================================
   1. FACT ORDER

   Business process:
   Order lifecycle and delivery performance

   Grain:
   One row per order
   ========================================================= */

IF OBJECT_ID('dw.FactOrder', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactOrder
    (
        FactOrderKey INT IDENTITY(1,1) NOT NULL,

        /* Degenerate business identifier */
        OrderID VARCHAR(32) NOT NULL,

        /* Dimension keys */
        CustomerKey INT NOT NULL,

        PurchaseDateKey INT NOT NULL,

        DeliveryDateKey INT NULL,

        EstimatedDeliveryDateKey INT NOT NULL,

        /* Descriptive operational attribute */
        OrderStatus VARCHAR(30) NOT NULL,

        /* Additive / derived measures */
        OrderCount TINYINT NOT NULL,

        DeliveryDays INT NULL,

        DelayDays INT NULL,

        OnTimeFlag BIT NULL,

        /*
           Decimal is required because some orders have
           multiple reviews whose average is fractional.
        */
        ReviewScore DECIMAL(4,2) NULL,

        CONSTRAINT PK_FactOrder
            PRIMARY KEY (FactOrderKey),

        CONSTRAINT UQ_FactOrder_OrderID
            UNIQUE (OrderID),

        CONSTRAINT FK_FactOrder_Customer
            FOREIGN KEY (CustomerKey)
            REFERENCES dw.DimCustomer(CustomerKey),

        CONSTRAINT FK_FactOrder_PurchaseDate
            FOREIGN KEY (PurchaseDateKey)
            REFERENCES dw.DimDate(DateKey),

        CONSTRAINT FK_FactOrder_DeliveryDate
            FOREIGN KEY (DeliveryDateKey)
            REFERENCES dw.DimDate(DateKey),

        CONSTRAINT FK_FactOrder_EstimatedDate
            FOREIGN KEY (EstimatedDeliveryDateKey)
            REFERENCES dw.DimDate(DateKey),

        CONSTRAINT CK_FactOrder_OrderCount
            CHECK (OrderCount = 1),

        CONSTRAINT CK_FactOrder_OnTimeFlag
            CHECK
            (
                OnTimeFlag IN (0,1)
                OR OnTimeFlag IS NULL
            )
    );

    PRINT 'Created dw.FactOrder';
END;
GO


/* =========================================================
   2. FACT SALES ITEM

   Business process:
   Product sales at order-item level

   Grain:
   One row per (order_id + order_item_id)
   ========================================================= */

IF OBJECT_ID('dw.FactSalesItem', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactSalesItem
    (
        FactSalesItemKey INT IDENTITY(1,1) NOT NULL,

        /* Degenerate order identifiers */
        OrderID VARCHAR(32) NOT NULL,

        OrderItemID INT NOT NULL,

        /* Dimension keys */
        CustomerKey INT NOT NULL,

        PurchaseDateKey INT NOT NULL,

        ProductKey INT NOT NULL,

        SellerKey INT NOT NULL,

        /* Measures */
        Price DECIMAL(18,2) NOT NULL,

        FreightValue DECIMAL(18,2) NOT NULL,

        ItemTotal DECIMAL(18,2) NOT NULL,

        ItemCount TINYINT NOT NULL,

        CONSTRAINT PK_FactSalesItem
            PRIMARY KEY (FactSalesItemKey),

        CONSTRAINT UQ_FactSalesItem_OrderItem
            UNIQUE
            (
                OrderID,
                OrderItemID
            ),

        CONSTRAINT FK_FactSalesItem_Customer
            FOREIGN KEY (CustomerKey)
            REFERENCES dw.DimCustomer(CustomerKey),

        CONSTRAINT FK_FactSalesItem_PurchaseDate
            FOREIGN KEY (PurchaseDateKey)
            REFERENCES dw.DimDate(DateKey),

        CONSTRAINT FK_FactSalesItem_Product
            FOREIGN KEY (ProductKey)
            REFERENCES dw.DimProduct(ProductKey),

        CONSTRAINT FK_FactSalesItem_Seller
            FOREIGN KEY (SellerKey)
            REFERENCES dw.DimSeller(SellerKey),

        CONSTRAINT CK_FactSalesItem_ItemCount
            CHECK (ItemCount = 1),

        CONSTRAINT CK_FactSalesItem_Price
            CHECK (Price >= 0),

        CONSTRAINT CK_FactSalesItem_Freight
            CHECK (FreightValue >= 0)
    );

    PRINT 'Created dw.FactSalesItem';
END;
GO


/* =========================================================
   3. FACT PAYMENT

   Business process:
   Customer payment transactions

   Grain:
   One row per
   (order_id + payment_sequential)
   ========================================================= */

IF OBJECT_ID('dw.FactPayment', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactPayment
    (
        FactPaymentKey INT IDENTITY(1,1) NOT NULL,

        /* Source transaction identifiers */
        OrderID VARCHAR(32) NOT NULL,

        PaymentSequential INT NOT NULL,

        /* Dimension keys */
        CustomerKey INT NOT NULL,

        PurchaseDateKey INT NOT NULL,

        PaymentTypeKey INT NOT NULL,

        /* Measures */
        PaymentInstallments INT NOT NULL,

        PaymentValue DECIMAL(18,2) NOT NULL,

        PaymentCount TINYINT NOT NULL,

        CONSTRAINT PK_FactPayment
            PRIMARY KEY (FactPaymentKey),

        CONSTRAINT UQ_FactPayment_Transaction
            UNIQUE
            (
                OrderID,
                PaymentSequential
            ),

        CONSTRAINT FK_FactPayment_Customer
            FOREIGN KEY (CustomerKey)
            REFERENCES dw.DimCustomer(CustomerKey),

        CONSTRAINT FK_FactPayment_PurchaseDate
            FOREIGN KEY (PurchaseDateKey)
            REFERENCES dw.DimDate(DateKey),

        CONSTRAINT FK_FactPayment_PaymentType
            FOREIGN KEY (PaymentTypeKey)
            REFERENCES dw.DimPaymentType(PaymentTypeKey),

        CONSTRAINT CK_FactPayment_PaymentCount
            CHECK (PaymentCount = 1),

        CONSTRAINT CK_FactPayment_Value
            CHECK (PaymentValue >= 0),

        CONSTRAINT CK_FactPayment_Installments
            CHECK (PaymentInstallments >= 0)
    );

    PRINT 'Created dw.FactPayment';
END;
GO


/* =========================================================
   4. VERIFY FACT TABLES
   ========================================================= */

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables AS t

INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id

WHERE s.name = 'dw'
  AND t.name LIKE 'Fact%'

ORDER BY t.name;
GO


/* =========================================================
   5. VERIFY FOREIGN KEYS
   ========================================================= */

SELECT
    fk.name AS ForeignKeyName,

    OBJECT_SCHEMA_NAME(
        fk.parent_object_id
    ) AS FactSchema,

    OBJECT_NAME(
        fk.parent_object_id
    ) AS FactTable,

    OBJECT_SCHEMA_NAME(
        fk.referenced_object_id
    ) AS DimensionSchema,

    OBJECT_NAME(
        fk.referenced_object_id
    ) AS DimensionTable

FROM sys.foreign_keys AS fk

WHERE OBJECT_SCHEMA_NAME(
          fk.parent_object_id
      ) = 'dw'

  AND OBJECT_NAME(
          fk.parent_object_id
      ) LIKE 'Fact%'

ORDER BY
    FactTable,
    ForeignKeyName;
GO