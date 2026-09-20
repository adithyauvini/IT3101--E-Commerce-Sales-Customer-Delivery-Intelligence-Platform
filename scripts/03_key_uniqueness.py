import pandas as pd
from pathlib import Path

RAW_FOLDER = Path("data/raw")

# Candidate keys for each source file
key_columns = {
    "olist_customers_dataset.csv": ["customer_id"],
    "olist_orders_dataset.csv": ["order_id"],
    "olist_order_items_dataset.csv": ["order_id", "order_item_id"],
    "olist_order_payments_dataset.csv": ["order_id", "payment_sequential"],
    "olist_order_reviews_dataset.csv": ["review_id"],
    "olist_products_dataset.csv": ["product_id"],
    "olist_sellers_dataset.csv": ["seller_id"],
    "product_category_name_translation.csv": ["product_category_name"],
}

print("=" * 70)
print("OLIST E-COMMERCE KEY UNIQUENESS CHECK")
print("=" * 70)

for filename, keys in key_columns.items():

    file = RAW_FOLDER / filename
    df = pd.read_csv(file)

    print(f"\n{'=' * 20} {filename} {'=' * 20}")
    print(f"Rows: {len(df):,}")
    print(f"Key: {', '.join(keys)}")

    # Check missing key values
    missing_keys = df[keys].isnull().any(axis=1).sum()

    # Check duplicate key combinations
    duplicate_keys = df.duplicated(subset=keys).sum()

    # Number of unique key combinations
    unique_keys = df[keys].drop_duplicates().shape[0]

    print(f"Missing key values: {missing_keys:,}")
    print(f"Unique key combinations: {unique_keys:,}")
    print(f"Duplicate key combinations: {duplicate_keys:,}")

    if missing_keys == 0 and duplicate_keys == 0:
        print("Status: PASS - key is unique and complete.")
    else:
        print("Status: REVIEW - key requires investigation.")

print("\n" + "=" * 70)
print("KEY UNIQUENESS CHECK COMPLETED")
print("=" * 70)