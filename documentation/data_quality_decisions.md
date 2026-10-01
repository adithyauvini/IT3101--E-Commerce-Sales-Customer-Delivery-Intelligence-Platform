# Data Quality and Transformation Decisions

## 1. Review Data

### Finding

The Olist review dataset contains 99,224 review records.

Investigation found:

- 789 review IDs occur more than once.
- These duplicate review IDs involve 1,603 rows.
- 789 duplicated review IDs are associated with multiple orders.
- No duplicated review ID was found with different review scores.
- 547 orders have multiple unique review IDs.
- 543 orders have 2 unique review IDs.
- 4 orders have 3 unique review IDs.

### Decision

`review_id` will not be treated as a unique primary key in the analytical warehouse.

Because `FactOrder` has a grain of one row per order, multiple review records associated with the same order will be aggregated during ETL.

The order-level review score will be calculated as:

    Average Review Score = AVG(review_score)

grouped by `order_id`.

### Handling

- One review for an order → use that score.
- Multiple reviews for an order → calculate the average score.
- No review for an order → retain NULL.
- Raw review records will not be deleted or modified.

### Reason

The raw layer must preserve the original source data. Aggregation is performed only during the staging/warehouse transformation process so that the FactOrder grain remains one row per order.