import pandas as pd
from pathlib import Path

file = Path("data/raw/olist_order_reviews_dataset.csv")

df = pd.read_csv(file)

print("=" * 70)
print("REVIEW KEY INVESTIGATION")
print("=" * 70)

# Find rows where review_id is duplicated
duplicates = df[df.duplicated("review_id", keep=False)].copy()

print(f"\nTotal review rows: {len(df):,}")
print(f"Unique review IDs: {df['review_id'].nunique():,}")
print(f"Rows involved in duplicate review IDs: {len(duplicates):,}")

print("\nNumber of duplicated review IDs:")
print(
    duplicates["review_id"]
    .value_counts()
    .value_counts()
    .sort_index()
)

print("\nNumber of orders with multiple review rows:")

reviews_per_order = df.groupby("order_id").size()

print(
    reviews_per_order[reviews_per_order > 1]
    .describe()
)

print("\nExample duplicate review IDs:")
print(
    duplicates[
        [
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message"
        ]
    ]
    .sort_values("review_id")
    .head(20)
    .to_string(index=False)
)

print("\n" + "=" * 70)
print("REVIEW KEY INVESTIGATION COMPLETED")
print("=" * 70)