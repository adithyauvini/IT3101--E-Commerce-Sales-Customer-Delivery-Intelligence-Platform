# Data Mart Documentation

This document records the final Data Mart design used in the corrected Olist Data Warehouse and Business Intelligence project.

The Data Mart layer is implemented in the SQL Server schema:

    mart

The MART layer provides reporting-ready views that simplify Power BI development and keep business logic consistent.

The four final MART views are:

1. `mart.vw_ExecutiveKPIs`
2. `mart.vw_SalesPerformance`
3. `mart.vw_DeliveryPerformance`
4. `mart.vw_PaymentAnalysis`

---

# 1. Data Mart Purpose

The purpose of the MART layer is to provide simplified analytical datasets for business users and Power BI.

The MART layer sits between the dimensional warehouse and the presentation layer:

    DW Facts and Dimensions
             ↓
           MART
             ↓
         Power BI

The main benefits are:

- Simplified reporting logic
- Consistent KPI definitions
- Reduced need for complex joins in Power BI
- Clear analytical grain
- Faster dashboard development
- Easier validation of business measures

---

# 2. Target Users

The MART layer supports several types of analytical users.

## Executive / Management Users

Main needs:

- Overall order performance
- Sales totals
- Customer counts
- Delivery performance
- Review performance

Primary view:

    mart.vw_ExecutiveKPIs

---

## Sales and Product Analysts

Main needs:

- Sales by month
- Sales by category
- Sales by customer state
- Sales by seller state
- Product performance
- Freight analysis

Primary view:

    mart.vw_SalesPerformance

---

## Operations and Logistics Analysts

Main needs:

- Delivery duration
- Late delivery analysis
- On-time delivery rate
- Delivery status
- Review score comparison

Primary view:

    mart.vw_DeliveryPerformance

---

## Finance / Payment Analysts

Main needs:

- Payment type analysis
- Payment value
- Installment analysis
- Payment transaction counts

Primary view:

    mart.vw_PaymentAnalysis

---

# 3. `mart.vw_ExecutiveKPIs`

## Purpose

Provides a single-row executive summary containing the main validated business KPIs.

## Grain

    One row for the complete analytical dataset

## Main Fields

- `TotalOrders`
- `OrdersWithItems`
- `OrdersWithPayments`
- `UniqueCustomers`
- `TotalItems`
- `ProductSalesValue`
- `FreightValue`
- `GrossItemValue`
- `TotalPaymentValue`
- `AverageOrderValue`
- `OrdersWithDeliveryDate`
- `OnTimeOrders`
- `LateOrders`
- `OnTimeDeliveryPercentage`
- `AverageDeliveryDays`
- `AverageReviewScore`
- `PaymentTransactions`

## KPI Definitions

### Total Orders

    TotalOrders = total rows from FactOrder

Validated value:

    99,441

---

### Orders With Items

Orders represented in `FactSalesItem`.

Validated value:

    98,666

---

### Orders With Payments

Orders represented in `FactPayment`.

Validated value:

    99,440

---

### Unique Customers

Distinct real customers based on:

    CustomerUniqueID

Validated value:

    96,096

---

### Total Items

Total item rows from `FactSalesItem`.

Validated value:

    112,650

---

### Product Sales Value

    ProductSalesValue = SUM(Price)

Validated value:

    13,591,643.70

This is the main sales measure used in Power BI.

---

### Freight Value

    FreightValue = SUM(FreightValue)

Validated value:

    2,251,909.54

---

### Gross Item Value

    GrossItemValue = SUM(ItemTotal)

where:

    ItemTotal = Price + FreightValue

Validated value:

    15,843,553.24

---

### Total Payment Value

    TotalPaymentValue = SUM(PaymentValue)

Validated value:

    16,008,872.12

This is kept separate from Product Sales because payment value and sales value are different business concepts.

---

### Average Order Value

Calculated using:

    Gross Item Value / Orders With Items

Validated value:

    160.58

---

### On-Time Delivery Percentage

Calculated using:

    On-Time Orders / Orders With Delivery Date × 100

Validated value:

    91.89%

---

### Average Delivery Days

Validated value:

    12.50

---

### Average Review Score

Validated value:

    approximately 4.09

The underlying review score is aggregated at order grain.

---

### Payment Transactions

Validated value:

    103,886

---

# 4. `mart.vw_SalesPerformance`

## Purpose

Provides a denormalised reporting view for sales, product, customer, seller, geographic, freight, and time analysis.

## Grain

    One row per order item

This matches the grain of:

    dw.FactSalesItem

## Row Count

    112,650

## Main Fields

### Transaction Fields

- `FactSalesItemKey`
- `OrderID`
- `OrderItemID`

### Time Fields

- `PurchaseDate`
- `DayOfMonth`
- `MonthNumber`
- `MonthName`
- `QuarterNumber`
- `QuarterName`
- `YearNumber`
- `YearMonthKey`
- `YearMonthLabel`

### Customer Fields

- `CustomerID`
- `CustomerUniqueID`
- Customer ZIP code
- `CustomerCity`
- `CustomerState`

### Product Fields

- `ProductID`
- `ProductCategoryPortuguese`
- `ProductCategoryEnglish`

### Seller Fields

- `SellerID`
- Seller ZIP code
- `SellerCity`
- `SellerState`

### Measures

- `Price`
- `FreightValue`
- `ItemTotal`
- `ItemCount`

## Analytical Uses

This view supports:

- Total Sales by Month
- Monthly Order Trend
- Monthly Freight Trend
- Top Product Categories by Sales
- Sales by Customer State
- Sales by Seller State
- Year filtering
- Product Category filtering
- Year → Quarter → Month drill-down
- Detailed sales record analysis

## Important Note

Because this view is at order-item grain:

    COUNT(OrderID)

does not represent unique orders.

For order counts, Power BI must use:

    DISTINCTCOUNT(OrderID)

---

# 5. `mart.vw_DeliveryPerformance`

## Purpose

Provides an order-level view for delivery and customer-experience analysis.

## Grain

    One row per order

This matches the grain of:

    dw.FactOrder

## Row Count

    99,441

## Main Fields

### Order Fields

- `OrderID`
- `OrderStatus`
- `OrderCount`

### Customer Fields

- Customer identifiers
- Customer ZIP code
- Customer city
- Customer state

### Time Fields

- Purchase date
- Year
- Quarter
- Month
- Actual delivery date
- Estimated delivery date

### Delivery Measures

- `DeliveryDays`
- `DelayDays`
- `OnTimeFlag`

### Delivery Status

A reporting-friendly label is created:

- `On Time`
- `Late`
- `Not Delivered`

### Customer Experience Measure

- `ReviewScore`

## Analytical Uses

This view supports:

- On-time delivery analysis
- Late delivery analysis
- Average delivery days
- Delivery status comparison
- Review score comparison
- Regional delivery analysis
- Operational performance analysis

---

# 6. `mart.vw_PaymentAnalysis`

## Purpose

Provides a payment-transaction-level reporting view.

## Grain

    One row per payment transaction

This matches the grain of:

    dw.FactPayment

## Row Count

    103,886

## Main Fields

### Order and Time Fields

- `OrderID`
- Purchase date
- Year
- Quarter
- Month

### Customer Fields

- Customer identifiers
- Customer city
- Customer state

### Payment Fields

- `PaymentType`
- `PaymentInstallments`
- `PaymentValue`
- `PaymentCount`

## Analytical Uses

This view supports:

- Payment type comparison
- Payment value analysis
- Installment analysis
- Payment transaction counts
- Payment trends over time
- Regional payment analysis

---

# 7. MART Row Count Validation

Final validated row counts are:

| MART View | Grain | Rows |
|---|---|---:|
| `vw_ExecutiveKPIs` | One summary row | 1 |
| `vw_SalesPerformance` | One row per order item | 112,650 |
| `vw_DeliveryPerformance` | One row per order | 99,441 |
| `vw_PaymentAnalysis` | One row per payment transaction | 103,886 |

These values match the expected warehouse grains.

---

# 8. MART and Power BI Mapping

The final Power BI report uses the MART views as follows.

## Executive Summary Page

Primary sources:

    mart.vw_ExecutiveKPIs
    mart.vw_SalesPerformance

Used for:

- KPI cards
- Total Sales by Month
- Top 10 Product Categories by Sales

---

## Trend Analysis Page

Primary source:

    mart.vw_SalesPerformance

Used for:

- Monthly Sales Trend
- Monthly Order Trend
- Monthly Freight Trend
- Year slicer
- Product Category slicer

---

## Interactive Analysis Page

Primary source:

    mart.vw_SalesPerformance

Used for:

- Year slicer
- Product Category slicer
- Sales drill-down
- Customer State analysis
- Seller State analysis
- Detail table

---

# 9. Business Logic Consistency

The MART layer keeps important measures separate.

## Product Sales

    Product Sales = SUM(Price)

## Freight Value

    Freight Value = SUM(FreightValue)

## Gross Item Value

    Gross Item Value = Product Sales + Freight Value

## Payment Value

    Payment Value = SUM(PaymentValue)

These values are not treated as interchangeable because they represent different business concepts.

---

# 10. Analytical Benefits

The Data Mart provides several analytical benefits.

## Simpler Power BI Development

Power BI can use reporting-ready columns without rebuilding complex joins.

## Consistent Measures

Validated definitions are applied before data reaches the dashboard.

## Clear Grain

Each MART view preserves a known analytical grain.

## Faster Investigation

Users can analyse sales, delivery, and payment activity using dedicated views.

## Better Traceability

Every MART result can be traced back to DW facts and dimensions.

## Reduced Double Counting

Separate views and explicit grain definitions reduce the risk of mixing order, item, and payment measures incorrectly.

---

# 11. Final Data Mart Summary

The project contains four reporting-ready MART views:

    vw_ExecutiveKPIs
    vw_SalesPerformance
    vw_DeliveryPerformance
    vw_PaymentAnalysis

Together they provide:

- Executive KPI reporting
- Sales analysis
- Product analysis
- Customer analysis
- Seller analysis
- Geographic analysis
- Delivery analysis
- Review analysis
- Payment analysis
- Time-based analysis

The MART layer provides the final analytical bridge between the dimensional warehouse and Power BI.
