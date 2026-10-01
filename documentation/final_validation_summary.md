# Final Validation Summary

This document records the final validation results for the corrected Olist Data Warehouse and Business Intelligence project.

The purpose of this validation is to confirm that:

- Source files were loaded correctly
- RAW and STG layers contain the expected number of records
- Dimension and fact tables were loaded successfully
- Fact grains are unique
- Foreign-key relationships are valid
- Missing delivery and review data are handled correctly
- Monetary measures match the source/staging totals
- MART views contain the expected number of rows
- Executive KPI values are consistent with the validated warehouse

The final validation was executed using:

    14_final_verification.sql

---

# 1. RAW Layer Validation

The RAW row counts were checked against the original source CSV files.

| RAW Table | Expected Rows | Actual Rows | Status |
|---|---:|---:|---|
| Customers | 99,441 | 99,441 | PASS |
| Geolocation | 1,000,163 | 1,000,163 | PASS |
| Order Items | 112,650 | 112,650 | PASS |
| Payments | 103,886 | 103,886 | PASS |
| Reviews | 99,224 | 99,224 | PASS |
| Orders | 99,441 | 99,441 | PASS |
| Products | 32,951 | 32,951 | PASS |
| Sellers | 3,095 | 3,095 | PASS |
| Translation | 71 | 71 | PASS |

## Result

All RAW table row counts match the original source files.

---

# 2. RAW to STG Validation

The RAW and STG row counts were compared after staging transformations.

## Result

For all nine source datasets:

    RAW row count = STG row count

No source records were lost during staging transformation.

Status:

    PASS

---

# 3. Staging Key Validation

The staging layer was checked for missing required business keys and duplicate business grain.

## Required Key NULL Checks

Required business-key NULL issues:

    0

## Duplicate Checks

Duplicate `customer_id`:

    0

Duplicate `order_id`:

    0

Duplicate `(order_id, order_item_id)`:

    0

Duplicate `(order_id, payment_sequential)`:

    0

Duplicate `(review_id, order_id)`:

    0

Duplicate `product_id`:

    0

Duplicate `seller_id`:

    0

## Result

All required staging business grains are valid.

Status:

    PASS

---

# 4. Order Missing-Value Validation

Total orders:

    99,441

Missing approval timestamps:

    160

Missing carrier delivery timestamps:

    1,783

Missing customer delivery timestamps:

    2,965

Missing purchase timestamps:

    0

Missing estimated delivery timestamps:

    0

Delivered orders without customer delivery timestamp:

    8

## Result

The missing-value patterns are preserved and handled explicitly in warehouse logic.

Status:

    PASS

---

# 5. Review Validation

Total review rows:

    99,224

Orders with multiple reviews:

    547

Maximum review records for one order:

    3

Orders with fractional review averages:

    123

Orders without a review in `FactOrder`:

    768

Invalid review scores:

    0

## Important Decision

Multiple reviews are aggregated to order grain using:

    AVG(review_score)

No-review orders retain:

    ReviewScore = NULL

## Result

The review logic preserves the one-row-per-order grain of `FactOrder`.

Status:

    PASS

---

# 6. Product Missing-Value Validation

Total products:

    32,951

Products missing category and main descriptive attributes:

    610

Products missing physical dimensions:

    2

The 610 products with missing category information are still preserved in the analytical model.

## Result

Missing descriptive values do not cause product records or related sales rows to be removed.

Status:

    PASS

---

# 7. Geolocation Validation

Total geolocation rows:

    1,000,163

Distinct ZIP prefixes:

    19,015

Invalid geolocation rows detected during typed staging validation:

    0

Customer ZIP prefixes:

    14,994

Customer ZIP prefixes matched to geolocation:

    14,837

Customer ZIP prefixes without geolocation:

    157

Seller ZIP prefixes:

    2,246

Seller ZIP prefixes matched to geolocation:

    2,239

Seller ZIP prefixes without geolocation:

    7

## Result

Location records are consolidated safely and unmatched ZIP prefixes are preserved using fallback logic.

Status:

    PASS

---

# 8. Dimension Validation

Final dimension row counts are:

| Dimension | Rows |
|---|---:|
| `dw.DimDate` | 800 |
| `dw.DimLocation` | 19,178 |
| `dw.DimCustomer` | 99,442 |
| `dw.DimProduct` | 32,952 |
| `dw.DimSeller` | 3,096 |
| `dw.DimPaymentType` | 6 |

## Date Dimension Range

Minimum date:

    2016-09-04

Maximum date:

    2018-11-12

## Technical Unknown Members

The following dimensions use surrogate key `0` for technical unknown members:

- Customer
- Product
- Seller
- Location
- Payment Type

## Result

All dimension tables were loaded successfully.

Status:

    PASS

---

# 9. Fact Row Count Validation

Final fact row counts are:

| Fact Table | Grain | Rows |
|---|---|---:|
| `dw.FactOrder` | One row per order | 99,441 |
| `dw.FactSalesItem` | One row per order item | 112,650 |
| `dw.FactPayment` | One row per payment transaction | 103,886 |

## Result

Fact counts match the expected business grains.

Status:

    PASS

---

# 10. Fact Grain Validation

The fact tables were checked for duplicate business grain.

Duplicate `FactOrder` order grain:

    0

Duplicate `(OrderID, OrderItemID)` in `FactSalesItem`:

    0

Duplicate `(OrderID, PaymentSequential)` in `FactPayment`:

    0

## Result

All fact grains are unique.

Status:

    PASS

---

# 11. Unknown Dimension Key Validation

Loaded fact rows were checked for technical unknown dimension keys.

Unknown customer keys used in facts:

    0

Unknown product keys used in facts:

    0

Unknown seller keys used in facts:

    0

Unknown payment type keys used in facts:

    0

## Result

The current source data fully matches the required fact dimensions.

Status:

    PASS

---

# 12. Delivery Measure Validation

Orders without actual customer delivery date:

    2,965

For these orders, the warehouse correctly stores:

    DeliveryDateKey = NULL
    DeliveryDays = NULL
    DelayDays = NULL
    OnTimeFlag = NULL

Orders with actual delivery date:

    96,476

On-time orders:

    88,649

Late orders:

    7,827

On-Time Delivery Percentage:

    91.89%

Average Delivery Days:

    12.50

## Result

Undelivered orders are not incorrectly classified as on-time or late.

Status:

    PASS

---

# 13. Item Total Validation

The derived measure is:

    ItemTotal = Price + FreightValue

Rows with incorrect calculated ItemTotal:

    0

## Result

All sales-item totals are correct.

Status:

    PASS

---

# 14. Monetary Validation

Staging and warehouse monetary totals were compared.

## Product Sales

Staging:

    13,591,643.70

Fact:

    13,591,643.70

Status:

    MATCH

---

## Freight Value

Staging:

    2,251,909.54

Fact:

    2,251,909.54

Status:

    MATCH

---

## Gross Item Value

Calculated as:

    Product Sales + Freight

Validated value:

    15,843,553.24

---

## Payment Value

Staging:

    16,008,872.12

Fact:

    16,008,872.12

Status:

    MATCH

---

# 15. Order Coverage Audit

Total orders:

    99,441

Orders with sales items:

    98,666

Orders with payments:

    99,440

Orders without sales items:

    775

Orders without payment:

    1

## Orders Without Items by Status

| Status | Orders |
|---|---:|
| unavailable | 603 |
| canceled | 164 |
| created | 5 |
| invoiced | 2 |
| shipped | 1 |

## Result

The difference between order count and sales-item count is explained by source business status rather than missing ETL records.

Status:

    PASS

---

# 16. Item and Payment Difference Audit

Orders compared:

    99,441

Orders where payment value matches item + freight value:

    98,092

Orders with a difference:

    1,349

Total difference:

    165,318.88

## Important Interpretation

Product Sales, Gross Item Value, and Payment Value represent different business concepts and are therefore kept as separate measures.

They must not all be labelled as "Sales".

---

# 17. Foreign-Key Validation

The dimensional warehouse contains:

    11 explicit foreign-key relationships

The final verification confirmed that the required foreign-key constraints exist between fact and dimension tables and between location-linked dimensions.

## Result

Referential integrity is implemented explicitly.

Status:

    PASS

---

# 18. MART Validation

The final MART views are:

- `mart.vw_ExecutiveKPIs`
- `mart.vw_SalesPerformance`
- `mart.vw_DeliveryPerformance`
- `mart.vw_PaymentAnalysis`

Final row counts:

| MART View | Rows |
|---|---:|
| `vw_ExecutiveKPIs` | 1 |
| `vw_SalesPerformance` | 112,650 |
| `vw_DeliveryPerformance` | 99,441 |
| `vw_PaymentAnalysis` | 103,886 |

## Result

All four reporting views exist and contain the expected number of rows.

Status:

    PASS

---

# 19. Executive KPI Validation

The final validated KPI snapshot is:

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

## Result

The KPI view returns one validated summary row and is consistent with the warehouse facts.

Status:

    PASS

---

# 20. Power BI Validation

The final Power BI report uses the validated MART layer.

The report contains:

1. Executive Summary
2. Trend Analysis
3. Interactive Analysis

Validated Power BI functionality includes:

- KPI cards
- Chronological monthly sales trend
- Top 10 product-category analysis
- Monthly distinct-order trend
- Monthly freight trend
- Year slicer
- Product-category slicer
- Customer-state comparison
- Seller-state comparison
- Year → Quarter → Month drill-down
- Month → Quarter → Year roll-up
- Detailed record table

## Result

The Power BI report is connected to the corrected analytical model and uses validated business definitions.

Status:

    PASS

---

# 21. Final Validation Result

All major validation areas completed successfully.

## Final Status

    RAW Load                PASS
    Staging Load            PASS
    Staging Data Quality    PASS
    Dimension Load          PASS
    Fact Load               PASS
    Fact Grain              PASS
    Foreign Keys            PASS
    Delivery Logic          PASS
    Review Logic            PASS
    Monetary Reconciliation PASS
    MART Views              PASS
    Executive KPIs          PASS
    Power BI                PASS

The corrected Olist DWBI solution is internally consistent from source data through the Power BI presentation layer.
