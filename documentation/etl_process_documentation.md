# ETL Process Documentation

This document records the complete Extract, Transform, and Load process used in the corrected Olist Data Warehouse and Business Intelligence project.

The ETL pipeline is implemented in SQL Server using the database:

    OlistDWBI

The overall flow is:

    Source CSV Files
          ↓
        RAW
          ↓
        STG
          ↓
     Dimensions
          ↓
        Facts
          ↓
        MART
          ↓
      Power BI

The ETL process was designed to be reproducible, auditable, and suitable for analytical processing.

---

# 1. ETL Objectives

The ETL process has the following objectives:

- Preserve original source data
- Load all source records into SQL Server
- Standardise and convert source values
- Handle missing and inconsistent data safely
- Preserve valid business records rather than deleting them unnecessarily
- Create dimension tables with surrogate keys
- Create fact tables at clearly defined grains
- Validate row counts and business rules
- Produce reporting-ready MART views
- Support Power BI analysis

---

# 2. Source Extraction

## Source Format

The project uses nine CSV files from the Olist Brazilian E-Commerce dataset.

The source files are:

1. `olist_customers_dataset.csv`
2. `olist_geolocation_dataset.csv`
3. `olist_order_items_dataset.csv`
4. `olist_order_payments_dataset.csv`
5. `olist_order_reviews_dataset.csv`
6. `olist_orders_dataset.csv`
7. `olist_products_dataset.csv`
8. `olist_sellers_dataset.csv`
9. `product_category_name_translation.csv`

## SQL Server Import Location

For SQL Server `BULK INSERT`, the source files are copied to:

    C:\DWBI\OlistRaw

This directory is readable by the SQL Server service account.

## Extraction Method

The RAW load uses:

    BULK INSERT

with CSV handling including:

- Header row skipped
- UTF-8 encoding
- Double-quote field handling
- Direct load into RAW tables

---

# 3. RAW Layer

## Purpose

The RAW layer stores source data with minimal transformation.

The goal is to preserve the original source representation before data cleaning or conversion.

## RAW Tables

- `raw.olist_customers`
- `raw.olist_geolocation`
- `raw.olist_order_items`
- `raw.olist_order_payments`
- `raw.olist_order_reviews`
- `raw.olist_orders`
- `raw.olist_products`
- `raw.olist_sellers`
- `raw.product_category_name_translation`

## Design Decision

RAW columns are primarily stored as character data.

This reduces the risk of source rows being rejected during initial loading because of formatting problems.

## RAW Row Counts

| Source | RAW Rows |
|---|---:|
| Customers | 99,441 |
| Geolocation | 1,000,163 |
| Order Items | 112,650 |
| Payments | 103,886 |
| Reviews | 99,224 |
| Orders | 99,441 |
| Products | 32,951 |
| Sellers | 3,095 |
| Translation | 71 |

The RAW counts match the original source files.

---

# 4. Staging Layer

## Purpose

The staging layer converts raw character data into typed and standardised values.

## Staging Tables

The project contains typed staging tables corresponding to the nine source datasets.

## Main Transformations

### Whitespace Cleaning

Leading and trailing whitespace is removed using:

    LTRIM(RTRIM(...))

### Empty String Handling

Empty strings are converted to NULL using:

    NULLIF(value, '')

### Numeric Conversion

Numeric source fields are converted using safe conversion logic such as:

    TRY_CONVERT(...)

Examples include:

- Price
- Freight value
- Payment value
- Installments
- Review score
- Product dimensions
- Product weight
- Geolocation coordinates

### Date and Timestamp Conversion

Source date and timestamp values are converted to:

    DATETIME2(0)

Examples include:

- Order purchase timestamp
- Approval timestamp
- Carrier delivery timestamp
- Customer delivery timestamp
- Estimated delivery date
- Shipping limit date
- Review creation date
- Review answer timestamp

### Text Standardisation

The following values are standardised:

- Order status → lowercase
- Payment type → lowercase
- State code → uppercase

### Product Numeric Conversion

Some product numeric source values may appear in decimal-like text form.

The staging process safely converts these values before loading the warehouse.

---

# 5. Staging Validation

The staging layer is validated before dimensional loading.

## Key Validation Checks

The following checks were performed:

- NULL checks on required business keys
- Duplicate customer keys
- Duplicate order keys
- Duplicate order-item grain
- Duplicate payment grain
- Duplicate review composite grain
- Duplicate product keys
- Duplicate seller keys
- Review score range validation
- Missing order timestamp analysis
- Product missing-value analysis
- Geolocation validation
- Translation-gap analysis

## Important Validation Results

### Orders

Total orders:

    99,441

Missing approval timestamp:

    160

Missing carrier delivery timestamp:

    1,783

Missing customer delivery timestamp:

    2,965

Delivered orders missing actual customer delivery timestamp:

    8

### Reviews

Orders with multiple reviews:

    547

Maximum reviews for one order:

    3

Orders with fractional average review score after aggregation:

    123

### Products

Products with missing category and descriptive attributes:

    610

Products with missing physical dimensions:

    2

### Payments

Orders without payment records:

    1

### Translation

Two Portuguese categories have no English translation.

### Geolocation

Total geolocation rows:

    1,000,163

Distinct ZIP prefixes:

    19,015

---

# 6. Dimension Source Audit

Before loading dimensions, the source values required by dimensions were audited.

## Date Range

The required date range is:

    2016-09-04 to 2018-11-12

This range is based on purchase, delivery, and estimated delivery dates.

## Payment Types

Source payment types include:

- credit_card
- boleto
- voucher
- debit_card
- not_defined

## Customer Geography

Distinct customer ZIP prefixes:

    14,994

Customer ZIP prefixes matched to geolocation:

    14,837

Customer ZIP prefixes without geolocation:

    157

## Seller Geography

Distinct seller ZIP prefixes:

    2,246

Seller ZIP prefixes matched to geolocation:

    2,239

Seller ZIP prefixes without geolocation:

    7

---

# 7. Dimension Loading

The dimension tables are loaded before the fact tables.

## Loading Order

A safe loading order is:

1. `DimDate`
2. `DimLocation`
3. `DimCustomer`
4. `DimProduct`
5. `DimSeller`
6. `DimPaymentType`

This ensures that referenced dimension rows exist before fact loading.

---

## 7.1 Date Dimension

The date dimension is generated dynamically from the required minimum and maximum dates.

The dimension includes:

- Day
- Month
- Quarter
- Year
- YearMonthKey
- YearMonthLabel

Final row count:

    800

---

## 7.2 Location Dimension

The location dimension is built from:

- Geolocation ZIP prefixes
- Customer ZIP prefixes
- Seller ZIP prefixes

### Consolidation Logic

For ZIP prefixes with multiple geolocation rows:

- Average latitude and longitude are calculated
- Most frequent city/state combination is selected
- Customer/seller location values are used as fallback when needed

### Unknown Member

The technical unknown location member is:

    LocationKey = 0

Final row count:

    19,178

---

## 7.3 Customer Dimension

Customers are loaded using:

- CustomerID
- CustomerUniqueID
- Matched LocationKey

Unknown customer member:

    CustomerKey = 0

Final row count:

    99,442

---

## 7.4 Product Dimension

Products are loaded with:

- Product business key
- Portuguese category
- English category
- Product descriptive attributes
- Product physical attributes

### Category Fallback

Category translation logic:

1. Use English translation when available
2. Otherwise use Portuguese category
3. Otherwise use Unknown

Unknown product member:

    ProductKey = 0

Final row count:

    32,952

---

## 7.5 Seller Dimension

Sellers are loaded with matched location keys.

Unknown seller member:

    SellerKey = 0

Final row count:

    3,096

---

## 7.6 Payment Type Dimension

Source payment types are loaded as distinct members.

Technical unknown:

    PaymentTypeKey = 0
    PaymentType = unknown

The real source value:

    not_defined

is preserved separately.

Final row count:

    6

---

# 8. Fact Loading

Fact tables are loaded after all required dimensions are available.

The fact tables are:

- `dw.FactOrder`
- `dw.FactSalesItem`
- `dw.FactPayment`

---

# 9. FactOrder ETL

## Grain

    One row per order

## Source

Main source:

    stg.olist_orders

Additional source:

    stg.olist_order_reviews

## Review Aggregation

Multiple reviews for one order are aggregated before loading the fact.

The order-level review score is:

    AVG(review_score)

This preserves the one-row-per-order fact grain.

If an order has no review:

    ReviewScore = NULL

## Delivery Measures

### Delivery Days

    DATEDIFF(day, PurchaseDate, ActualDeliveryDate)

### Delay Days

    DATEDIFF(day, EstimatedDeliveryDate, ActualDeliveryDate)

### On-Time Flag

    1 = delivered on or before estimated date
    0 = delivered after estimated date
    NULL = no actual delivery date

## Final Row Count

    99,441

---

# 10. FactSalesItem ETL

## Grain

    One row per order item

Unique business grain:

    (OrderID, OrderItemID)

## Source

Main source:

    stg.olist_order_items

with joins to:

- Orders
- Customer dimension
- Product dimension
- Seller dimension
- Date dimension

## Measures

### Price

Product sale amount.

### Freight Value

Shipping/freight value.

### Item Total

    ItemTotal = Price + FreightValue

### Item Count

    ItemCount = 1

## Final Row Count

    112,650

---

# 11. FactPayment ETL

## Grain

    One row per payment transaction

Unique business grain:

    (OrderID, PaymentSequential)

## Source

Main source:

    stg.olist_order_payments

with joins to:

- Orders
- Customer dimension
- Payment type dimension
- Date dimension

## Measures

- PaymentInstallments
- PaymentValue
- PaymentCount

## Final Row Count

    103,886

---

# 12. Fact Validation

The fact tables are validated after loading.

## Grain Validation

Duplicate grain violations:

    FactOrder = 0
    FactSalesItem = 0
    FactPayment = 0

## Unknown Dimension Key Validation

Fact rows using technical unknown dimension members:

    0

## Delivery NULL Validation

Orders without actual customer delivery date:

    2,965

For these orders:

- DeliveryDateKey = NULL
- DeliveryDays = NULL
- DelayDays = NULL
- OnTimeFlag = NULL

## Review Validation

Orders without reviews:

    768

Orders with fractional review score:

    123

## Item Total Validation

Incorrect item totals:

    0

---

# 13. Monetary Validation

The source and fact monetary totals were compared.

## Product Sales

    13,591,643.70

## Freight Value

    2,251,909.54

## Gross Item Value

    15,843,553.24

## Payment Value

    16,008,872.12

The fact values match the staging totals for the corresponding measures.

---

# 14. KPI Source Audit

Before building MART views, KPI sources were audited to prevent incorrect business definitions.

## Orders

Total orders:

    99,441

Orders with items:

    98,666

Orders with payments:

    99,440

Orders without items:

    775

## Orders Without Items by Status

- unavailable: 603
- canceled: 164
- created: 5
- invoiced: 2
- shipped: 1

## Delivery KPI Base

Orders with delivery date:

    96,476

On-time orders:

    88,649

Late orders:

    7,827

Average delivery days:

    12.50

Average review score:

    approximately 4.09

---

# 15. MART Creation

After fact validation, reporting views are created in the `mart` schema.

The final MART views are:

- `mart.vw_ExecutiveKPIs`
- `mart.vw_SalesPerformance`
- `mart.vw_DeliveryPerformance`
- `mart.vw_PaymentAnalysis`

These views simplify Power BI development and ensure consistent business logic.

---

# 16. Final MART Validation

Final row counts:

| MART View | Rows |
|---|---:|
| `vw_ExecutiveKPIs` | 1 |
| `vw_SalesPerformance` | 112,650 |
| `vw_DeliveryPerformance` | 99,441 |
| `vw_PaymentAnalysis` | 103,886 |

---

# 17. Final KPI Validation

The final Executive KPI results are:

| KPI | Value |
|---|---:|
| Total Orders | 99,441 |
| Orders With Items | 98,666 |
| Orders With Payments | 99,440 |
| Unique Customers | 96,096 |
| Total Items | 112,650 |
| Product Sales Value | 13,591,643.70 |
| Freight Value | 2,251,909.54 |
| Gross Item Value | 15,843,553.24 |
| Total Payment Value | 16,008,872.12 |
| Average Order Value | 160.58 |
| Orders With Delivery Date | 96,476 |
| On-Time Orders | 88,649 |
| Late Orders | 7,827 |
| On-Time Delivery Percentage | 91.89% |
| Average Delivery Days | 12.50 |
| Average Review Score | 4.09 |
| Payment Transactions | 103,886 |

---

# 18. ETL Script Execution Order

The final SQL execution order is:

    01_create_database.sql
    02_create_raw_tables.sql
    03_load_raw_data.sql
    04_create_staging_tables.sql
    05_load_staging.sql
    06_validate_staging.sql
    07_dimension_source_audit.sql
    08_create_dimensions.sql
    09_load_dimensions.sql
    10_create_facts.sql
    11_load_facts.sql
    12_kpi_source_audit.sql
    13_create_mart_views.sql
    14_final_verification.sql

This order should be followed from top to bottom when rebuilding the project.

---

# 19. ETL Validation Summary

The final validation confirms:

- RAW counts match source files
- RAW and STG counts match
- Dimension loads completed successfully
- Fact loads completed successfully
- Fact grains are unique
- No fact rows use technical unknown members
- Monetary values match staging totals
- Foreign-key relationships are valid
- MART row counts match expected fact grains
- Executive KPI values are validated
- Power BI uses the validated MART layer

---

# 20. Final ETL Summary

The completed ETL pipeline performs:

    Extract
      ↓
    Load original CSV values into RAW
      ↓
    Transform and standardise into STG
      ↓
    Load dimensions
      ↓
    Load facts
      ↓
    Validate warehouse results
      ↓
    Build MART views
      ↓
    Validate KPIs
      ↓
    Load into Power BI

The ETL process preserves source traceability while producing a clean, typed, dimensional warehouse suitable for Business Intelligence analysis.
