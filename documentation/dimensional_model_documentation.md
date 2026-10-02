# Dimensional Model Documentation

This document records the final dimensional warehouse design used in the corrected Olist Data Warehouse and Business Intelligence project.

The dimensional model is implemented in the `dw` schema of the SQL Server database:

    OlistDWBI

The warehouse contains:

- 6 dimension tables
- 3 fact tables

The design supports sales, customer, seller, delivery, review, payment, product, geographic, and time-based analysis.

---

## 1. Dimensional Modelling Approach

The project uses dimensional modelling principles with fact tables linked to descriptive dimensions through surrogate keys.

The main goals of the model are:

- Clear analytical grain
- Consistent business measures
- Reusable dimensions
- Explicit primary-key and foreign-key relationships
- Support for time hierarchies
- Support for Power BI reporting and drill-down analysis

The model uses separate fact tables because orders, sales items, and payments have different grains.

---

# 2. Dimension Tables

## 2.1 `dw.DimDate`

### Purpose

Provides reusable calendar attributes for time-based analysis.

### Primary Key

    DateKey

### Key Type

Integer in `YYYYMMDD` format.

Example:

    20180115

### Main Attributes

- `DateKey`
- `FullDate`
- `DayOfMonth`
- `DayName`
- `MonthNumber`
- `MonthName`
- `QuarterNumber`
- `QuarterName`
- `YearNumber`
- `YearMonthKey`
- `YearMonthLabel`

### Hierarchy

    Year
      ↓
    Quarter
      ↓
    Month
      ↓
    Day

### Date Range

The date dimension covers the full required warehouse period:

    2016-09-04 to 2018-11-12

### Number of Rows

    800

---

## 2.2 `dw.DimLocation`

### Purpose

Stores geographic information at ZIP-code-prefix level.

### Primary Key

    LocationKey

### Business Key

    ZipCodePrefix

### Main Attributes

- `LocationKey`
- `ZipCodePrefix`
- `City`
- `State`
- `Latitude`
- `Longitude`
- `HasGeolocation`

### Unknown Member

A technical unknown location record is stored as:

    LocationKey = 0

This allows unmatched or unavailable location references to remain valid without breaking fact-to-dimension relationships.

### Number of Rows

    19,178

---

## 2.3 `dw.DimCustomer`

### Purpose

Stores customer identifiers and links customers to geographic information.

### Primary Key

    CustomerKey

### Business Key

    CustomerID

### Main Attributes

- `CustomerKey`
- `CustomerID`
- `CustomerUniqueID`
- `LocationKey`

### Foreign Key

    LocationKey → dw.DimLocation(LocationKey)

### Important Design Decision

`CustomerID` identifies the operational customer record.

`CustomerUniqueID` is retained because the same real customer may appear under multiple `CustomerID` values across purchases.

### Unknown Member

A technical unknown customer member is stored as:

    CustomerKey = 0

### Number of Rows

    99,442

This includes:

- 99,441 source customers
- 1 technical unknown member

---

## 2.4 `dw.DimProduct`

### Purpose

Stores product information and product-category descriptions.

### Primary Key

    ProductKey

### Business Key

    ProductID

### Main Attributes

- `ProductKey`
- `ProductID`
- `ProductCategoryPortuguese`
- `ProductCategoryEnglish`
- Product name length
- Product description length
- Product photos quantity
- Product weight
- Product length
- Product height
- Product width

### Translation Logic

Product categories are translated using the source translation table.

Fallback logic is applied as follows:

1. Use English translation when available.
2. If no English translation exists, retain the Portuguese category.
3. If the source category is missing, use an appropriate unknown label.

### Important Data Quality Decision

Products with missing category or descriptive values are preserved rather than deleted.

### Unknown Member

A technical unknown product member is stored as:

    ProductKey = 0

### Number of Rows

    32,952

This includes:

- 32,951 source products
- 1 technical unknown member

---

## 2.5 `dw.DimSeller`

### Purpose

Stores seller information and links sellers to location.

### Primary Key

    SellerKey

### Business Key

    SellerID

### Main Attributes

- `SellerKey`
- `SellerID`
- `LocationKey`

### Foreign Key

    LocationKey → dw.DimLocation(LocationKey)

### Unknown Member

A technical unknown seller member is stored as:

    SellerKey = 0

### Number of Rows

    3,096

This includes:

- 3,095 source sellers
- 1 technical unknown member

---

## 2.6 `dw.DimPaymentType`

### Purpose

Stores payment-type categories for payment analysis.

### Primary Key

    PaymentTypeKey

### Business Key

    PaymentType

### Main Attributes

- `PaymentTypeKey`
- `PaymentType`

### Source Payment Types

The source contains:

- `credit_card`
- `boleto`
- `voucher`
- `debit_card`
- `not_defined`

### Important Design Decision

The source value:

    not_defined

is preserved as a real source category.

A separate technical member:

    unknown

is used for warehouse fallback purposes.

### Unknown Member

    PaymentTypeKey = 0

### Number of Rows

    6

This includes:

- 5 source payment types
- 1 technical unknown member

---

# 3. Fact Tables

## 3.1 `dw.FactOrder`

### Business Process

Order and delivery performance analysis.

### Grain

    One row per order

This grain is enforced by a unique constraint on:

    OrderID

### Primary Key

    FactOrderKey

### Degenerate Dimension

    OrderID

is stored directly in the fact table because it is an operational identifier useful for analysis and traceability.

### Foreign Keys

- `CustomerKey` → `dw.DimCustomer`
- `PurchaseDateKey` → `dw.DimDate`
- `DeliveryDateKey` → `dw.DimDate`
- `EstimatedDeliveryDateKey` → `dw.DimDate`

### Measures

- `OrderCount`
- `DeliveryDays`
- `DelayDays`
- `OnTimeFlag`
- `ReviewScore`

### Measure Definitions

#### Order Count

    OrderCount = 1

This supports additive order counting.

#### Delivery Days

    DeliveryDays = DATEDIFF(day, PurchaseDate, ActualDeliveryDate)

If the order has no actual customer delivery date:

    DeliveryDays = NULL

#### Delay Days

    DelayDays = DATEDIFF(day, EstimatedDeliveryDate, ActualDeliveryDate)

Interpretation:

- Negative value → delivered early
- Zero → delivered on estimated date
- Positive value → delivered late
- NULL → not delivered

#### On-Time Flag

    1 = Delivered on or before estimated delivery date
    0 = Delivered after estimated delivery date
    NULL = No actual customer delivery date

#### Review Score

Review records are aggregated to order grain.

If one order contains multiple review records:

    ReviewScore = AVG(review_score)

The value is stored as a decimal because some order-level averages are fractional.

### Number of Rows

    99,441

---

## 3.2 `dw.FactSalesItem`

### Business Process

Product sales and freight analysis.

### Grain

    One row per order item

The business grain is uniquely identified by:

    (OrderID, OrderItemID)

### Primary Key

    FactSalesItemKey

### Foreign Keys

- `CustomerKey` → `dw.DimCustomer`
- `PurchaseDateKey` → `dw.DimDate`
- `ProductKey` → `dw.DimProduct`
- `SellerKey` → `dw.DimSeller`

### Measures

- `Price`
- `FreightValue`
- `ItemTotal`
- `ItemCount`

### Measure Definitions

#### Product Sales

    Price

This is the product sale amount excluding freight.

#### Freight Value

    FreightValue

This represents the shipping/freight amount for the order item.

#### Item Total

    ItemTotal = Price + FreightValue

This measure is also referred to as Gross Item Value when aggregated.

#### Item Count

    ItemCount = 1

### Number of Rows

    112,650

---

## 3.3 `dw.FactPayment`

### Business Process

Payment transaction analysis.

### Grain

    One row per payment transaction

The business grain is uniquely identified by:

    (OrderID, PaymentSequential)

### Primary Key

    FactPaymentKey

### Foreign Keys

- `CustomerKey` → `dw.DimCustomer`
- `PurchaseDateKey` → `dw.DimDate`
- `PaymentTypeKey` → `dw.DimPaymentType`

### Measures

- `PaymentInstallments`
- `PaymentValue`
- `PaymentCount`

### Measure Definitions

#### Payment Value

    PaymentValue

Represents the monetary value of the payment transaction.

#### Payment Count

    PaymentCount = 1

### Number of Rows

    103,886

---

# 4. Fact Grain Summary

| Fact Table | Grain | Unique Business Key |
|---|---|---|
| `dw.FactOrder` | One row per order | `OrderID` |
| `dw.FactSalesItem` | One row per order item | `(OrderID, OrderItemID)` |
| `dw.FactPayment` | One row per payment transaction | `(OrderID, PaymentSequential)` |

Keeping these grains separate prevents double counting between orders, items, and payments.

---

# 5. Main Measures Summary

| Measure | Fact | Definition |
|---|---|---|
| Total Orders | `FactOrder` | `SUM(OrderCount)` |
| Product Sales | `FactSalesItem` | `SUM(Price)` |
| Freight Value | `FactSalesItem` | `SUM(FreightValue)` |
| Gross Item Value | `FactSalesItem` | `SUM(ItemTotal)` |
| Total Items | `FactSalesItem` | `SUM(ItemCount)` |
| Payment Value | `FactPayment` | `SUM(PaymentValue)` |
| Payment Transactions | `FactPayment` | `SUM(PaymentCount)` |
| Average Delivery Days | `FactOrder` | `AVG(DeliveryDays)` |
| Average Review Score | `FactOrder` | `AVG(ReviewScore)` |
| On-Time Delivery % | `FactOrder` | On-time delivered orders / delivered orders |

---

# 6. Relationship Structure

The warehouse contains explicit foreign-key relationships.

## FactOrder Relationships

    DimCustomer
         ↑
      CustomerKey
         |
     FactOrder
      /     |      \
Purchase  Delivery  Estimated
 DateKey   DateKey   DateKey
    ↑        ↑         ↑
           DimDate

---

## FactSalesItem Relationships

            DimCustomer
                 ↑
                 |
            FactSalesItem
          /      |       \
   DimDate   DimProduct   DimSeller

Seller and customer dimensions connect to `DimLocation` through `LocationKey`.

---

## FactPayment Relationships

            DimCustomer
                 ↑
                 |
            FactPayment
             /      \
        DimDate   DimPaymentType

---

# 7. Location Relationships

Customer geography:

    Fact
      ↓
    DimCustomer
      ↓
    DimLocation

Seller geography:

    FactSalesItem
      ↓
    DimSeller
      ↓
    DimLocation

This supports regional analysis without storing city and state repeatedly in the fact tables.

---

# 8. Surrogate Keys

The dimensions use integer surrogate keys such as:

- `CustomerKey`
- `ProductKey`
- `SellerKey`
- `LocationKey`
- `PaymentTypeKey`

Surrogate keys are used instead of operational string identifiers inside fact relationships.

Benefits include:

- Smaller fact-table keys
- Stable warehouse relationships
- Separation from operational identifiers
- Support for warehouse-specific unknown members

---

# 9. Unknown Member Strategy

The warehouse reserves surrogate key `0` for technical unknown members in relevant dimensions.

Examples:

    CustomerKey = 0
    ProductKey = 0
    SellerKey = 0
    LocationKey = 0
    PaymentTypeKey = 0

This strategy prevents missing dimension matches from causing broken referential integrity.

Final validation confirmed that no loaded fact rows require unknown dimension keys for the current dataset.

---

# 10. Hierarchies

## Date Hierarchy

The main analytical hierarchy is:

    YearNumber
        ↓
    QuarterName
        ↓
    YearMonthLabel
        ↓
    DayOfMonth

This hierarchy is used by Power BI for drill-down and roll-up.

---

## Geographic Analysis

Although the location dimension is stored at ZIP-prefix level, reporting uses higher-level geographic attributes such as:

    State
      ↓
    City
      ↓
    ZIP Code Prefix

This supports regional comparison across customer and seller locations.

---

# 11. Dimensional Model Validation

The final warehouse validation confirmed:

- `FactOrder` rows: **99,441**
- `FactSalesItem` rows: **112,650**
- `FactPayment` rows: **103,886**
- Duplicate fact grain violations: **0**
- Unknown fact dimension keys: **0**
- Explicit foreign-key relationships: **11**

Dimension counts:

- `DimDate`: **800**
- `DimLocation`: **19,178**
- `DimCustomer`: **99,442**
- `DimProduct`: **32,952**
- `DimSeller`: **3,096**
- `DimPaymentType`: **6**

---

# 12. Design Assumptions

The final model uses the following assumptions:

1. `FactOrder` represents exactly one order.
2. `FactSalesItem` represents exactly one order item.
3. `FactPayment` represents exactly one payment transaction.
4. Product sales and payment values are separate business concepts.
5. Freight is not included in Product Sales.
6. `ItemTotal` is defined as Product Price plus Freight Value.
7. Review scores are aggregated to order grain before loading `FactOrder`.
8. Orders without an actual delivery date retain NULL delivery measures.
9. Source records with missing descriptive attributes are preserved where possible.
10. Technical unknown members use surrogate key `0`.
11. Source value `not_defined` is not treated as the same thing as technical `unknown`.
12. Time analysis is driven by the shared date dimension.

---

# 13. Final Model Summary

The final dimensional warehouse consists of:

## Dimensions

    DimDate
    DimLocation
    DimCustomer
    DimProduct
    DimSeller
    DimPaymentType

## Facts

    FactOrder
    FactSalesItem
    FactPayment

The model supports:

- Sales analysis
- Product analysis
- Customer analysis
- Seller analysis
- Delivery analysis
- Review analysis
- Payment analysis
- Geographic analysis
- Time-based drill-down and roll-up

The separate fact grains and explicit dimension relationships provide a reliable analytical foundation for the MART layer and Power BI dashboards.
