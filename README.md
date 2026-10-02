# Olist Data Warehouse and Business Intelligence Project

This project implements an end-to-end Data Warehouse and Business Intelligence solution using the Olist Brazilian E-Commerce dataset.

The solution covers:

- Source data profiling
- RAW data loading
- Staging and transformation
- Dimensional modelling
- Fact and dimension loading
- Data quality validation
- Data Mart creation
- Power BI dashboard development
- Business insight generation

The SQL Server database used by the project is:

    OlistDWBI

---

# 1. Project Architecture

The solution follows this layered architecture:

    Olist CSV Files
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

Database schemas:

- `raw`
- `stg`
- `dw`
- `mart`

---

# 2. Project Folder Structure

The final folder structure is:

    IT3101-Olist-Rebuild
    │
    ├── data
    │   └── raw
    │       ├── olist_customers_dataset.csv
    │       ├── olist_geolocation_dataset.csv
    │       ├── olist_order_items_dataset.csv
    │       ├── olist_order_payments_dataset.csv
    │       ├── olist_order_reviews_dataset.csv
    │       ├── olist_orders_dataset.csv
    │       ├── olist_products_dataset.csv
    │       ├── olist_sellers_dataset.csv
    │       └── product_category_name_translation.csv
    │
    ├── scripts
    │   ├── 01_data_quality.py
    │   ├── 02_key_relationship_profile.py
    │   └── 03_data_quality_investigation.py
    │
    ├── sql
    │   ├── 01_create_database.sql
    │   ├── 02_create_raw_tables.sql
    │   ├── 03_load_raw_data.sql
    │   ├── 04_create_staging_tables.sql
    │   ├── 05_load_staging.sql
    │   ├── 06_validate_staging.sql
    │   ├── 07_dimension_source_audit.sql
    │   ├── 08_create_dimensions.sql
    │   ├── 09_load_dimensions.sql
    │   ├── 10_create_facts.sql
    │   ├── 11_load_facts.sql
    │   ├── 12_kpi_source_audit.sql
    │   ├── 13_create_mart_views.sql
    │   └── 14_final_verification.sql
    │
    ├── powerbi
    │   └── Olist_BI_Solution.pbix
    │
    ├── screenshots
    │
    ├── diagrams
    │
    ├── documentation
    │   ├── source_inventory.md
    │   ├── data_quality_decisions.md
    │   ├── data_warehouse_architecture.md
    │   ├── dimensional_model_documentation.md
    │   ├── etl_process_documentation.md
    │   ├── data_mart_documentation.md
    │   ├── power_bi_dashboard_documentation.md
    │   ├── final_validation_summary.md
    │   ├── 01_sales_trend_insight.md
    │   ├── 02_product_category_insight.md
    │   ├── 03_delivery_performance_insight.md
    │   ├── 04_regional_sales_insight.md
    │   └── 05_customer_retention_insight.md
    │
    ├── references
    │
    └── README.md

---

# 3. Prerequisites

The project was developed using:

- Windows
- SQL Server
- SQL Server Management Studio
- Python 3
- pandas
- Microsoft Power BI Desktop

Recommended system memory:

    8 GB RAM or higher

Because SQL Server and Power BI may consume significant memory, the SQL Server maximum memory was limited during development.

Example configuration used:

    max server memory = 3072 MB

---

# 4. Python Environment

The profiling scripts require Python and pandas.

Check Python:

    python --version

Install pandas if needed:

    pip install pandas

Run the profiling scripts from the project root:

    python scripts\01_data_quality.py
    python scripts\02_key_relationship_profile.py
    python scripts\03_data_quality_investigation.py

These scripts are used to inspect:

- Row counts
- Missing values
- Duplicate records
- Key uniqueness
- Source relationships
- Review behaviour
- Product missing data
- Geolocation issues
- Translation gaps

---

# 5. SQL Server Setup

## Database

The first SQL script creates:

    OlistDWBI

and the schemas:

    raw
    stg
    dw
    mart

---

# 6. SQL Server Import Folder

SQL Server `BULK INSERT` must be able to read the source CSV files.

Copy the nine Olist CSV files to:

    C:\DWBI\OlistRaw

The folder should contain:

    C:\DWBI\OlistRaw\olist_customers_dataset.csv
    C:\DWBI\OlistRaw\olist_geolocation_dataset.csv
    C:\DWBI\OlistRaw\olist_order_items_dataset.csv
    C:\DWBI\OlistRaw\olist_order_payments_dataset.csv
    C:\DWBI\OlistRaw\olist_order_reviews_dataset.csv
    C:\DWBI\OlistRaw\olist_orders_dataset.csv
    C:\DWBI\OlistRaw\olist_products_dataset.csv
    C:\DWBI\OlistRaw\olist_sellers_dataset.csv
    C:\DWBI\OlistRaw\product_category_name_translation.csv

The SQL Server service account must have read access to this folder.

Example service account:

    NT SERVICE\MSSQLSERVER

A permission command may be used from an administrator Command Prompt if required:

    icacls C:\DWBI\OlistRaw /grant "NT SERVICE\MSSQLSERVER:(RX)" /T

---

# 7. SQL Script Execution Order

Run the SQL scripts in the following exact order:

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

Do not skip the validation scripts.

---

# 8. SQL Script Purpose

## `01_create_database.sql`

Creates:

- `OlistDWBI`
- `raw`
- `stg`
- `dw`
- `mart`

---

## `02_create_raw_tables.sql`

Creates the nine RAW tables that mirror the CSV source columns.

---

## `03_load_raw_data.sql`

Loads the nine CSV files into the RAW schema using SQL Server `BULK INSERT`.

---

## `04_create_staging_tables.sql`

Creates typed staging tables.

---

## `05_load_staging.sql`

Transforms RAW values into typed and standardised staging values.

---

## `06_validate_staging.sql`

Validates:

- Row counts
- Required keys
- Duplicate grains
- Missing timestamps
- Product missing values
- Review behaviour
- Geolocation
- Translation gaps

---

## `07_dimension_source_audit.sql`

Audits the source values required for dimensional loading.

---

## `08_create_dimensions.sql`

Creates:

- `dw.DimDate`
- `dw.DimLocation`
- `dw.DimCustomer`
- `dw.DimProduct`
- `dw.DimSeller`
- `dw.DimPaymentType`

---

## `09_load_dimensions.sql`

Loads all dimension tables and technical unknown members.

---

## `10_create_facts.sql`

Creates:

- `dw.FactOrder`
- `dw.FactSalesItem`
- `dw.FactPayment`

with primary keys, unique constraints, foreign keys, and checks.

---

## `11_load_facts.sql`

Loads the three fact tables using the corrected transformation logic.

---

## `12_kpi_source_audit.sql`

Audits the source measures before MART creation.

This script is especially important for distinguishing:

- Product Sales
- Freight Value
- Gross Item Value
- Payment Value

---

## `13_create_mart_views.sql`

Creates:

- `mart.vw_ExecutiveKPIs`
- `mart.vw_SalesPerformance`
- `mart.vw_DeliveryPerformance`
- `mart.vw_PaymentAnalysis`

---

## `14_final_verification.sql`

Performs the final end-to-end validation.

---

# 9. Expected Final Warehouse Counts

## Dimensions

| Dimension | Expected Rows |
|---|---:|
| `DimDate` | 800 |
| `DimLocation` | 19,178 |
| `DimCustomer` | 99,442 |
| `DimProduct` | 32,952 |
| `DimSeller` | 3,096 |
| `DimPaymentType` | 6 |

## Facts

| Fact | Expected Rows |
|---|---:|
| `FactOrder` | 99,441 |
| `FactSalesItem` | 112,650 |
| `FactPayment` | 103,886 |

## MART Views

| View | Expected Rows |
|---|---:|
| `vw_ExecutiveKPIs` | 1 |
| `vw_SalesPerformance` | 112,650 |
| `vw_DeliveryPerformance` | 99,441 |
| `vw_PaymentAnalysis` | 103,886 |

---

# 10. Expected Executive KPI Values

The final validated KPI values are:

| KPI | Expected Value |
|---|---:|
| Total Orders | 99,441 |
| Unique Customers | 96,096 |
| Total Items | 112,650 |
| Product Sales Value | 13,591,643.70 |
| Freight Value | 2,251,909.54 |
| Gross Item Value | 15,843,553.24 |
| Total Payment Value | 16,008,872.12 |
| Average Order Value | 160.58 |
| On-Time Delivery Percentage | 91.89% |
| Average Delivery Days | 12.50 |
| Average Review Score | 4.09 |
| Payment Transactions | 103,886 |

---

# 11. Power BI Setup

Open:

    powerbi\Olist_BI_Solution.pbix

If the SQL connection must be recreated, connect to:

Server:

    LAPTOP-G2G7GNQU

Database:

    OlistDWBI

Connection mode:

    Import

Authentication:

    Windows Authentication

Import the following views:

- `mart.vw_ExecutiveKPIs`
- `mart.vw_SalesPerformance`
- `mart.vw_DeliveryPerformance`
- `mart.vw_PaymentAnalysis`

---

# 12. Power BI Report Pages

The final report contains three pages:

## Page 1

    Executive Summary

Includes:

- Total Sales
- Total Orders
- Unique Customers
- Average Delivery Days
- Average Review Score
- On-Time Delivery %
- Total Sales by Month
- Top 10 Product Categories by Sales

---

## Page 2

    Trend Analysis

Includes:

- Year slicer
- Product Category slicer
- Monthly Sales Trend
- Monthly Order Trend
- Monthly Freight Trend

Important:

Monthly Order Trend must use:

    DISTINCTCOUNT(OrderID)

because the sales MART is at order-item grain.

---

## Page 3

    Interactive Analysis

Includes:

- Year slicer
- Product Category slicer
- Year → Quarter → Month drill-down
- Customer State sales analysis
- Seller State sales analysis
- Detail table
- Roll-up functionality

---

# 13. Important Business Definitions

## Total Sales

    SUM(Price)

Expected:

    13.59M

## Freight Value

    SUM(FreightValue)

Expected:

    2.25M

## Gross Item Value

    SUM(Price + FreightValue)

Expected:

    15.84M

## Payment Value

    SUM(PaymentValue)

Expected:

    16.01M

These values must remain separate because they represent different business concepts.

---

# 14. Important Data Quality Decisions

## Reviews

`review_id` is not treated as a unique warehouse primary key.

Multiple reviews for one order are aggregated using:

    AVG(review_score)

before loading `FactOrder`.

---

## Delivery

Orders without an actual customer delivery date retain:

    DeliveryDateKey = NULL
    DeliveryDays = NULL
    DelayDays = NULL
    OnTimeFlag = NULL

They are not classified as on-time.

---

## Products

Products with missing descriptive attributes are preserved.

Missing category information does not cause sales records to be removed.

---

## Unknown Members

Technical unknown members use surrogate key:

    0

where appropriate.

The source value:

    not_defined

is preserved separately from technical `unknown`.

---

# 15. Documentation

Detailed documentation is available in the `documentation` folder.

Recommended files:

- `source_inventory.md`
- `data_quality_decisions.md`
- `data_warehouse_architecture.md`
- `dimensional_model_documentation.md`
- `etl_process_documentation.md`
- `data_mart_documentation.md`
- `power_bi_dashboard_documentation.md`
- `final_validation_summary.md`
- Five business insight files

---

# 16. Final Rebuild Procedure

To rebuild the entire project from scratch:

1. Install SQL Server, SSMS, Python, pandas, and Power BI Desktop.
2. Place the Olist CSV files in `data\raw`.
3. Copy the same nine CSV files to `C:\DWBI\OlistRaw`.
4. Grant the SQL Server service account read permission to the import folder.
5. Run the Python profiling scripts.
6. Open SSMS.
7. Execute SQL scripts `01` through `14` in order.
8. Confirm the final verification results.
9. Open Power BI.
10. Connect to the `OlistDWBI` database.
11. Load the four MART views.
12. Verify the three dashboard pages.
13. Confirm slicers and drill-down functionality.
14. Save the final PBIX.
15. Capture final screenshots.
16. Prepare the final report and submission package.

---

# 17. Final Project Status

The corrected solution includes:

    Source Profiling        COMPLETE
    RAW Layer               COMPLETE
    Staging Layer           COMPLETE
    Dimensional Warehouse   COMPLETE
    ETL Pipeline            COMPLETE
    Data Mart               COMPLETE
    Validation              COMPLETE
    Power BI                COMPLETE
    Business Insights       COMPLETE
    Documentation           COMPLETE

The remaining submission work is focused on final screenshots, diagrams, report preparation and packaging of technical files.
