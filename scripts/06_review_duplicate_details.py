import pandas as pd
from pathlib import Path

file = Path("data/raw/olist_order_reviews_dataset.csv")

df = pd.read_csv(file)

print("=" * 70)
print("DUPLICATE REVIEW ID DETAILS")
print("=" * 70)

# Find review IDs that appear more than once
review_counts = df["review_id"].value_counts()

duplicate_ids = review_counts[review_counts > 1].index

duplicate_reviews = df[df["review_id"].isin(duplicate_ids)].copy()

print(f"\nTotal duplicate review IDs: {len(duplicate_ids):,}")
print(f"Total rows involving duplicate review IDs: {len(duplicate_reviews):,}")

# Check whether duplicate review IDs have different scores
score_variation = (
    duplicate_reviews
    .groupby("review_id")["review_score"]
    .nunique()
)

different_scores = score_variation[score_variation > 1]

print(f"\nDuplicate review IDs with different review scores: {len(different_scores):,}")

# Check whether duplicate review IDs are connected to multiple orders
orders_per_review = (
    duplicate_reviews
    .groupby("review_id")["order_id"]
    .nunique()
)

multiple_orders = orders_per_review[orders_per_review > 1]

print(f"Duplicate review IDs linked to multiple orders: {len(multiple_orders):,}")

# Show a few examples
print("\nExample duplicated review records:")
print(
    duplicate_reviews[
        [
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message"
        ]
    ]
    .head(20)
    .to_string(index=False)
)

print("\n" + "=" * 70)
print("DUPLICATE REVIEW DETAIL CHECK COMPLETED")
print("=" * 70)