# IT3101--E-Commerce-Sales-Customer-Delivery-Intelligence-Platform
End-to-end Data Warehousing and Business Intelligence solution for e-commerce sales, customer, payment, and delivery analytics using the Olist Brazilian E-Commerce dataset, SQL Server, T-SQL, and Power BI.

## 📌 Project Overview

This project develops an end-to-end **Data Warehousing and Business Intelligence (DWBI) solution** for analysing e-commerce sales, customers, payments, products, sellers, and delivery performance.

The project uses the **Olist Brazilian E-Commerce dataset** to transform raw e-commerce data into a structured data warehouse and analytical data mart, followed by interactive business intelligence dashboards.

## 🎯 Project Objectives

* Collect and prepare e-commerce data from multiple source files.
* Design and implement a dimensional data warehouse.
* Develop ETL processes for extraction, transformation, and loading.
* Create analytical fact and dimension tables.
* Develop a business-oriented data mart.
* Build interactive Power BI dashboards.
* Analyse sales, customer, payment, and delivery performance.
* Generate meaningful business insights to support decision-making.

## 🏢 Business Scenario

The platform is designed to support e-commerce business stakeholders in understanding:

* Sales performance and revenue trends
* Customer behaviour and purchasing activity
* Product and category performance
* Seller performance
* Payment methods and payment values
* Delivery performance and delays
* Customer review patterns
* Regional and location-based performance

## 🛠️ Technologies

| Technology                          | Purpose                                                 |
| ----------------------------------- | ------------------------------------------------------- |
| SQL Server 2022                     | Data warehouse and database                             |
| SQL Server Management Studio (SSMS) | Database development and management                     |
| T-SQL                               | ETL, transformations, validation and analytical queries |
| Power BI                            | Business intelligence dashboards and visual analytics   |
| Git & GitHub                        | Version control and project collaboration               |
| Olist Dataset                       | Source e-commerce data                                  |

## 📊 Data Sources

The project uses the Olist Brazilian E-Commerce dataset, including:

* `olist_customers_dataset.csv`
* `olist_orders_dataset.csv`
* `olist_order_items_dataset.csv`
* `olist_products_dataset.csv`
* `olist_sellers_dataset.csv`
* `olist_order_payments_dataset.csv`
* `olist_order_reviews_dataset.csv`
* `olist_geolocation_dataset.csv`
* `product_category_name_translation.csv`

## 🏗️ DWBI Architecture

The solution follows a layered architecture:

```text
Source Data
    ↓
Raw Layer
    ↓
Staging Layer
    ↓
Data Warehouse
    ↓
Data Mart
    ↓
Power BI / OLAP / Business Intelligence
```

## ⭐ Dimensional Model

The warehouse uses a dimensional modelling approach with fact and dimension tables.

### Fact Tables

* `FactSalesItem`
* `FactOrder`
* `FactPayment`

### Dimension Tables

* `DimDate`
* `DimCustomer`
* `DimProduct`
* `DimSeller`
* `DimLocation`
* `DimPaymentType`

The primary analytical grain of `FactSalesItem` is **one row per order line item**.

## 📈 Key Business KPIs

The project analyses key measures including:

* Sales Value
* Freight Value
* Total Item Value
* Number of Orders
* Number of Customers
* Average Order Value (AOV)
* Average Delivery Days
* On-Time Delivery Percentage
* Average Review Score
* Payment Value

## 📊 Power BI Dashboard

The final Power BI solution will contain three main pages:

### 1. Executive Summary

Provides a high-level overview of:

* Sales
* Orders
* Customers
* Average Order Value
* Delivery performance
* Customer reviews

### 2. Trend Analysis

Provides time-based analysis of:

* Monthly sales
* Order trends
* Product/category performance
* Regional performance
* Delivery and review trends

### 3. Interactive Analysis

Provides interactive analysis using:

* Slicers
* Filters
* Drill-down
* Roll-up
* Cross-filtering
* Tooltips
* Detailed analytical tables

## 📁 Project Structure

```text
IT3101--E-Commerce-Sales-Customer-Delivery-Intelligence-Platform/
│
├── README.md
│
├── data/
│   └── raw/
│
├── sql/
│   ├── 00_create_database.sql
│   ├── 01_create_schemas.sql
│   ├── 02_create_raw_tables.sql
│   ├── 03_load_raw.sql
│   ├── 04_staging_transformations.sql
│   ├── 05_load_dimensions.sql
│   ├── 06_load_facts.sql
│   ├── 07_create_data_mart.sql
│   ├── 08_validation_queries.sql
│   └── 09_business_analysis_queries.sql
│
├── powerbi/
│   └── Olist_DWBI.pbix
│
├── diagrams/
│   ├── architecture.png
│   ├── source_relationships.png
│   └── dimensional_model.png
│
├── screenshots/
│   ├── etl/
│   ├── database/
│   └── powerbi/
│
├── report/
│   └── final_report.docx
│
└── references/
```

## 👥 Team

**Module:** IT3101 – Data Warehousing & Business Intelligence

**Project:** E-Commerce Sales, Customer & Delivery Intelligence Platform

**Academic Year:** 2026

Team members and individual responsibilities will be documented here.

## 📌 Project Status

🚧 **Currently in development**

The project is being developed progressively through:

1. Data source preparation
2. Raw data loading
3. Staging and transformation
4. Dimensional warehouse implementation
5. ETL development
6. Data mart creation
7. Data validation
8. Power BI dashboard development
9. Business analysis
10. Final documentation

## 📚 Dataset

The project uses the Olist Brazilian E-Commerce dataset for academic analysis and implementation.

---

**IT3101 – Data Warehousing & Business Intelligence | 2026**
