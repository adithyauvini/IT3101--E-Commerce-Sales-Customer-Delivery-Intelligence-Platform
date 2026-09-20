import pandas as pd
from pathlib import Path

file = Path("data/raw/olist_order_reviews_dataset.csv")

df = pd.read_csv(file)

print("=" * 70)
print("REVIEW ↔ ORDER RELATIONSHIP CHECK")
print("=" * 70)

# Number of reviews per order
reviews_per_order = df.groupby("order_id")["review_id"].nunique()

# Orders with more than one unique review ID
multiple_reviews = reviews_per_order[reviews_per_order > 1]

print(f"\nTotal orders represented in reviews: {reviews_per_order.shape[0]:,}")
print(f"Orders with multiple unique review IDs: {len(multiple_reviews):,}")

if len(multiple_reviews) > 0:
    print("\nDistribution of unique reviews per order:")
    print(multiple_reviews.value_counts().sort_index())

# Check whether the same review ID is connected to multiple orders
orders_per_review = df.groupby("review_id")["order_id"].nunique()

multiple_orders = orders_per_review[orders_per_review > 1]

print(f"\nReview IDs linked to multiple orders: {len(multiple_orders):,}")

if len(multiple_orders) > 0:
    print("\nExample review IDs linked to multiple orders:")
    print(multiple_orders.head(10))

print("\n" + "=" * 70)
print("RELATIONSHIP CHECK COMPLETED")
print("=" * 70)