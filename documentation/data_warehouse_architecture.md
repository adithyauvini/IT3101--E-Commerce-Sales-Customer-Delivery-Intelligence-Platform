# Data Warehouse Architecture Documentation

This document records the final Data Warehouse and Business Intelligence architecture used in the corrected Olist e-commerce project.

The architecture follows a layered design:

    Source CSV Files
          ↓
        RAW
          ↓
        STG
          ↓
         DW
          ↓
        MART
          ↓
      Power BI

The solution is implemented in SQL Server using the database:

    OlistDWBI

The database contains four schemas:

- `raw`
- `stg`
- `dw`
- `mart`

---

## 1. Source Layer

### Purpose

The source layer contains the original Olist operational CSV files.

The raw source files are preserved without modification.

### Source Files

The project uses the following nine CSV files:

1. `olist_customers_dataset.csv`
2. `olist_geolocation_dataset.csv`
3. `olist_order_items_dataset.csv`
4. `olist_order_payments_dataset.csv`
5. `olist_order_reviews_dataset.csv`
6. `olist_orders_dataset.csv`
7. `olist_products_dataset.csv`
8. `olist_sellers_dataset.csv`
9. `product_category_name_translation.csv`

### Role

These files represent the operational source data used for extraction into the SQL Server environment.

---

## 2. RAW Layer

### Schema

    raw

### Purpose

The RAW layer stores the source data in a structure that closely mirrors the original CSV files.

The main objective is to preserve source values before transformation.

### RAW Tables

- `raw.olist_customers`
- `raw.olist_geolocation`
- `raw.olist_order_items`
- `raw.olist_order_payments`
- `raw.olist_order_reviews`
- `raw.olist_orders`
- `raw.olist_products`
- `raw.olist_sellers`
- `raw.product_category_name_translation`

### Design Decision

Most RAW columns are loaded as character values.

This avoids rejecting source rows during the initial extraction stage because of formatting or conversion problems.

### Loading Method

The CSV files are loaded into SQL Server using:

    BULK INSERT

The project uses CSV format handling with:

- Header row skipped
- UTF-8 encoding
- Double-quote field handling

---

## 3. Staging Layer

### Schema

    stg

### Purpose

The staging layer converts RAW source values into typed and standardised data.

This layer prepares source data for dimensional modelling.

### Main Transformations

The staging process performs transformations such as:

- Leading and trailing whitespace removal
- Empty strings converted to NULL
- Numeric conversion
- Date and timestamp conversion
- Standardisation of order status
- Standardisation of payment type
- State codes converted to uppercase
- Product measurements converted to numeric types

### Data Quality Validation

Validation checks are performed after staging.

Examples include:

- Required key NULL checks
- Duplicate business key checks
- Missing timestamp analysis
- Product missing-value analysis
- Review-score validation
- Multi-review order analysis
- Translation-gap analysis
- Geolocation validation

The staging row counts are compared with RAW row counts to verify that source records have not been unintentionally lost.

---

## 4. Data Warehouse Layer

### Schema

    dw

### Purpose

The DW layer stores the dimensional warehouse.

It contains dimension tables and fact tables designed for analytical processing.

---

## Dimension Tables

### `dw.DimDate`

Purpose:

Supports time-based analysis and hierarchy navigation.

Important attributes include:

- DateKey
- FullDate
- DayOfMonth
- MonthNumber
- MonthName
- QuarterNumber
- QuarterName
- YearNumber
- YearMonthKey
- YearMonthLabel

Hierarchy:

    Year
      ↓
    Quarter
      ↓
    Month
      ↓
    Day

---

### `dw.DimLocation`

Purpose:

Stores the consolidated ZIP-code-level geographic dimension.

Important attributes include:

- LocationKey
- ZipCodePrefix
- City
- State
- Latitude
- Longitude
- HasGeolocation

A technical unknown location member is stored using:

    LocationKey = 0

---

### `dw.DimCustomer`

Purpose:

Stores customer business keys and customer identity information.

Important attributes include:

- CustomerKey
- CustomerID
- CustomerUniqueID
- LocationKey

`CustomerKey` is the warehouse surrogate key.

---

### `dw.DimProduct`

Purpose:

Stores product information used for product and category analysis.

Important attributes include:

- ProductKey
- ProductID
- ProductCategoryPortuguese
- ProductCategoryEnglish
- Product dimensions and descriptive attributes

Missing product categories are preserved using an appropriate fallback rather than deleting product records.

---

### `dw.DimSeller`

Purpose:

Stores seller information for seller and regional analysis.

Important attributes include:

- SellerKey
- SellerID
- LocationKey

---

### `dw.DimPaymentType`

Purpose:

Stores the available payment types.

Important attributes include:

- PaymentTypeKey
- PaymentType

A technical `unknown` member is kept separately from the real source value `not_defined`.

---

## Fact Tables

### `dw.FactOrder`

### Grain

    One row per order

### Main Measures

- OrderCount
- DeliveryDays
- DelayDays
- OnTimeFlag
- ReviewScore

### Important Foreign Keys

- CustomerKey
- PurchaseDateKey
- DeliveryDateKey
- EstimatedDeliveryDateKey

### Important Design Decisions

`ReviewScore` is stored as a decimal because multiple review scores for one order can produce fractional order-level averages.

`OnTimeFlag` is NULL when no actual customer delivery date exists.

---

### `dw.FactSalesItem`

### Grain

    One row per order item

### Main Measures

- Price
- FreightValue
- ItemTotal
- ItemCount

### Important Foreign Keys

- CustomerKey
- PurchaseDateKey
- ProductKey
- SellerKey

### Derived Measure

    ItemTotal = Price + FreightValue

---

### `dw.FactPayment`

### Grain

    One row per payment transaction

### Main Measures

- PaymentInstallments
- PaymentValue
- PaymentCount

### Important Foreign Keys

- CustomerKey
- PurchaseDateKey
- PaymentTypeKey

---

## 5. Data Mart Layer

### Schema

    mart

### Purpose

The MART layer provides simplified analytical views for Power BI.

It separates reporting logic from the underlying fact and dimension tables.

### MART Views

#### `mart.vw_ExecutiveKPIs`

Purpose:

Provides one-row executive KPI results.

Includes:

- TotalOrders
- OrdersWithItems
- OrdersWithPayments
- UniqueCustomers
- TotalItems
- ProductSalesValue
- FreightValue
- GrossItemValue
- TotalPaymentValue
- AverageOrderValue
- OrdersWithDeliveryDate
- OnTimeOrders
- LateOrders
- OnTimeDeliveryPercentage
- AverageDeliveryDays
- AverageReviewScore
- PaymentTransactions

---

#### `mart.vw_SalesPerformance`

Purpose:

Supports sales, product, customer, seller, regional, and time analysis.

Grain:

    One row per sales item

Used heavily by the Power BI Executive Summary, Trend Analysis, and Interactive Analysis pages.

---

#### `mart.vw_DeliveryPerformance`

Purpose:

Supports order-level delivery analysis.

Grain:

    One row per order

Includes:

- DeliveryDays
- DelayDays
- OnTimeFlag
- DeliveryStatus
- ReviewScore

---

#### `mart.vw_PaymentAnalysis`

Purpose:

Supports payment-method and payment-transaction analysis.

Grain:

    One row per payment transaction

Includes:

- PaymentType
- PaymentInstallments
- PaymentValue
- PaymentCount

---

## 6. Presentation Layer

### Tool

    Microsoft Power BI

### Purpose

The presentation layer provides the final Business Intelligence interface.

The Power BI report contains three pages:

1. Executive Summary
2. Trend Analysis
3. Interactive Analysis

The report provides:

- KPI cards
- Line charts
- Bar charts
- Column charts
- Slicers
- Filters
- Drill-down
- Roll-up
- Regional comparisons
- Detailed record inspection

---

## 7. End-to-End Data Flow

The final project data flow is:

    Olist CSV Files
          ↓
    raw schema
          ↓
    stg schema
          ↓
    dw dimensions and facts
          ↓
    mart reporting views
          ↓
    Power BI dashboards

### Processing Sequence

1. Extract source CSV files.
2. Load the source data into RAW tables.
3. Transform RAW values into typed STG tables.
4. Validate staged data.
5. Create and load warehouse dimensions.
6. Create and load warehouse facts.
7. Validate fact grain, foreign keys, and measures.
8. Create MART reporting views.
9. Validate final KPI values.
10. Import MART views into Power BI.
11. Build analytical dashboards.

---

## 8. Architecture Benefits

The layered architecture provides the following benefits:

### Traceability

Source data can be traced from CSV files through RAW, STG, DW, MART, and Power BI.

### Data Quality

Transformations and validation are separated from source extraction.

### Reproducibility

The SQL scripts can recreate the complete warehouse in a controlled sequence.

### Maintainability

Each layer has a clear responsibility.

### Analytical Performance

The dimensional model and MART views simplify reporting and reduce complexity in Power BI.

### Business Consistency

Important measures such as Product Sales, Freight Value, Gross Item Value, Delivery Performance, and Review Score are defined consistently before they reach Power BI.

---

## 9. Final Architecture Summary

The final solution uses a layered SQL Server architecture:

    Source
      ↓
    RAW
      ↓
    STG
      ↓
    Enterprise Data Warehouse
      ↓
    Data Mart
      ↓
    Power BI

This design supports the complete DWBI process from operational source data to analytical reporting and business insight generation.
