# Power BI Dashboard Documentation

This document records the final Power BI dashboard design used in the corrected Olist Data Warehouse and Business Intelligence project.

The report is built from the validated MART layer in the `OlistDWBI` SQL Server database.

## Data Sources Used in Power BI

The following MART views are imported into Power BI:

- `mart.vw_ExecutiveKPIs`
- `mart.vw_SalesPerformance`
- `mart.vw_DeliveryPerformance`
- `mart.vw_PaymentAnalysis`

The dashboard uses the corrected warehouse and mart calculations rather than calculations from the original group project.

---

## Report Page 1 - Executive Summary

### Purpose

The Executive Summary page provides a high-level overview of business performance using the main KPIs and summary visualisations.

### KPI Cards

#### Total Sales

Field:

    ProductSalesValue

Source:

    mart.vw_ExecutiveKPIs

Validated value:

    13.59M

Definition:

    Total Sales = SUM(Price)

Freight is not included in this KPI.

---

#### Total Orders

Field:

    TotalOrders

Source:

    mart.vw_ExecutiveKPIs

Validated value:

    99,441

---

#### Unique Customers

Field:

    UniqueCustomers

Source:

    mart.vw_ExecutiveKPIs

Validated value:

    96,096

---

#### Average Delivery Days

Field:

    AverageDeliveryDays

Source:

    mart.vw_ExecutiveKPIs

Validated value:

    12.50

---

#### Average Review Score

Field:

    AverageReviewScore

Source:

    mart.vw_ExecutiveKPIs

Validated value:

    approximately 4.09

The review score is calculated at order grain after multiple review records for the same order are aggregated.

---

#### On-Time Delivery Percentage

Field:

    OnTimeDeliveryPercentage

Source:

    mart.vw_ExecutiveKPIs

Validated value:

    91.89%

---

### Visual 1 - Total Sales by Month

Visual type:

    Line Chart

Source:

    mart.vw_SalesPerformance

X-axis:

    YearMonthLabel

Y-axis:

    SUM(Price)

Sorting:

    YearMonthLabel is sorted by YearMonthKey in ascending order.

Purpose:

This chart shows the monthly sales trend across the available dataset period.

---

### Visual 2 - Top 10 Product Categories by Sales

Visual type:

    Clustered Bar Chart

Source:

    mart.vw_SalesPerformance

Y-axis:

    ProductCategoryEnglish

X-axis:

    SUM(Price)

Filter:

    Top N = 10

Purpose:

This chart identifies the product categories contributing the highest product sales value.

---

## Report Page 2 - Trend Analysis

### Purpose

The Trend Analysis page provides time-based analysis of sales, order activity, and freight value.

All visuals on this page use `mart.vw_SalesPerformance` so that the page slicers interact consistently with all charts.

### Slicer 1 - Year

Field:

    YearNumber

Purpose:

Allows the user to filter all trend visuals by year.

---

### Slicer 2 - Product Category

Field:

    ProductCategoryEnglish

Style:

    Dropdown

Purpose:

Allows the user to analyse trends for a selected product category or all categories.

---

### Visual 1 - Monthly Sales Trend

Visual type:

    Line Chart

X-axis:

    YearMonthLabel

Y-axis:

    SUM(Price)

Purpose:

Shows changes in total product sales over time.

---

### Visual 2 - Monthly Order Trend

Visual type:

    Line Chart

X-axis:

    YearMonthLabel

Y-axis:

    DISTINCTCOUNT(OrderID)

Reason for using distinct count:

`mart.vw_SalesPerformance` is at order-item grain. One order can therefore appear more than once when it contains multiple items.

Using a normal count would count item rows rather than unique orders.

---

### Visual 3 - Monthly Freight Trend

Visual type:

    Column Chart

X-axis:

    YearMonthLabel

Y-axis:

    SUM(FreightValue)

Purpose:

Shows how freight value changes over time and supports comparison with sales and order activity.

---

## Report Page 3 - Interactive Analysis

### Purpose

The Interactive Analysis page demonstrates OLAP-style interaction using slicers, filters, drill-down, roll-up, regional comparisons, and detailed records.

### Slicer 1 - Year

Field:

    YearNumber

Purpose:

Filters the interactive visuals by year.

---

### Slicer 2 - Product Category

Field:

    ProductCategoryEnglish

Style:

    Dropdown

Purpose:

Allows users to focus the analysis on a selected category.

---

## Drill-Down Visual

### Sales Drill-Down: Year → Quarter → Month

Visual type:

    Clustered Column Chart

Y-axis:

    SUM(Price)

Hierarchy:

    YearNumber
    QuarterName
    YearMonthLabel

Drill-down path:

    Year
      ↓
    Quarter
      ↓
    Month

Roll-up path:

    Month
      ↑
    Quarter
      ↑
    Year

Purpose:

The hierarchy allows users to move from a high-level yearly sales view to quarterly and monthly detail.

The drill-down and roll-up functions were tested successfully in Power BI.

---

## Regional Comparison Visuals

### Sales by Customer State

Visual type:

    Clustered Bar Chart

Y-axis:

    CustomerState

X-axis:

    SUM(Price)

Sorting:

    Descending by sales value

Purpose:

Shows the geographic distribution of sales based on customer location.

---

### Sales by Seller State

Visual type:

    Clustered Bar Chart

Y-axis:

    SellerState

X-axis:

    SUM(Price)

Sorting:

    Descending by sales value

Purpose:

Shows the geographic concentration of seller-generated sales.

---

## Detail Table

The detail table provides record-level information for interactive investigation.

Fields:

- `OrderID`
- `YearNumber`
- `QuarterName`
- `MonthName`
- `DayOfMonth`
- `ProductCategoryEnglish`
- `CustomerState`
- `SellerState`
- `Price`
- `FreightValue`

Purpose:

The table allows users to inspect individual records after applying slicers or interacting with charts.

---

## Final KPI Definitions

The final dashboard uses the following consistent business definitions.

### Product Sales

    Product Sales = SUM(Price)

Validated value:

    13,591,643.70

### Freight Value

    Freight Value = SUM(FreightValue)

Validated value:

    2,251,909.54

### Gross Item Value

    Gross Item Value = Product Sales + Freight Value

Validated value:

    15,843,553.24

### Payment Value

    Payment Value = SUM(PaymentValue)

Validated value:

    16,008,872.12

These measures are kept separate because they represent different business concepts.

---

## Dashboard Interaction Validation

The following functionality was tested successfully:

- Year filtering
- Product Category filtering
- Cross-filtering of visuals
- Chronological month sorting
- Distinct order counting
- Top 10 product-category filtering
- Drill-down from Year to Quarter to Month
- Roll-up from Month to Quarter to Year
- Customer state comparison
- Seller state comparison
- Detailed record inspection

## Result

The Power BI report provides:

- Executive-level KPI monitoring
- Time-based sales and order analysis
- Freight trend analysis
- Product-category comparison
- Regional analysis
- Interactive filtering
- Drill-down and roll-up
- Detailed record exploration

The final Power BI file should be saved as:

    Olist_BI_Solution.pbix
