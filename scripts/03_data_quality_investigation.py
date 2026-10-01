from pathlib import Path
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW = PROJECT_ROOT / "data" / "raw"


def load(name, **kwargs):
    return pd.read_csv(
        RAW / name,
        low_memory=False,
        **kwargs
    )


print("=" * 80)
print("OLIST TARGETED DATA QUALITY INVESTIGATION")
print("=" * 80)


# ============================================================
# Load relevant datasets
# ============================================================

orders = load("olist_orders_dataset.csv")
payments = load("olist_order_payments_dataset.csv")
reviews = load("olist_order_reviews_dataset.csv")
products = load("olist_products_dataset.csv")
translations = load("product_category_name_translation.csv")
items = load("olist_order_items_dataset.csv")
geo = load("olist_geolocation_dataset.csv")


# ============================================================
# 1. Order without payment
# ============================================================

print("\n" + "=" * 80)
print("1. ORDERS WITHOUT PAYMENTS")
print("=" * 80)

paid_order_ids = set(payments["order_id"])

orders_without_payment = orders[
    ~orders["order_id"].isin(paid_order_ids)
]

print(f"Orders without payment: {len(orders_without_payment):,}")

if not orders_without_payment.empty:
    print(
        orders_without_payment[
            [
                "order_id",
                "customer_id",
                "order_status",
                "order_purchase_timestamp"
            ]
        ].to_string(index=False)
    )


# ============================================================
# 2. Delivered orders with missing customer-delivery date
# ============================================================

print("\n" + "=" * 80)
print("2. DELIVERED ORDERS WITH MISSING DELIVERY DATE")
print("=" * 80)

delivered_missing = orders[
    (orders["order_status"] == "delivered")
    & (orders["order_delivered_customer_date"].isna())
]

print(f"Rows: {len(delivered_missing):,}")

if not delivered_missing.empty:
    print(
        delivered_missing[
            [
                "order_id",
                "order_status",
                "order_purchase_timestamp",
                "order_approved_at",
                "order_delivered_carrier_date",
                "order_delivered_customer_date",
                "order_estimated_delivery_date"
            ]
        ].to_string(index=False)
    )


# ============================================================
# 3. Review-ID duplication investigation
# ============================================================

print("\n" + "=" * 80)
print("3. DUPLICATED REVIEW IDs")
print("=" * 80)

duplicate_review_ids = reviews[
    reviews.duplicated(
        subset=["review_id"],
        keep=False
    )
].copy()

print(
    f"Rows using duplicated review IDs: "
    f"{len(duplicate_review_ids):,}"
)

print(
    f"Distinct duplicated review IDs: "
    f"{duplicate_review_ids['review_id'].nunique():,}"
)

review_id_order_counts = (
    duplicate_review_ids
    .groupby("review_id")["order_id"]
    .nunique()
)

print(
    "Duplicated review IDs linked to more than one order: "
    f"{(review_id_order_counts > 1).sum():,}"
)

print("\nExample duplicated review IDs:")

print(
    duplicate_review_ids[
        [
            "review_id",
            "order_id",
            "review_score",
            "review_creation_date"
        ]
    ]
    .sort_values(["review_id", "order_id"])
    .head(20)
    .to_string(index=False)
)


# ============================================================
# 4. Check whether (review_id + order_id) is unique
# ============================================================

print("\n" + "=" * 80)
print("4. REVIEW COMPOSITE KEY TEST")
print("=" * 80)

review_composite_duplicates = reviews.duplicated(
    subset=["review_id", "order_id"],
    keep=False
)

print(
    "Rows duplicated by (review_id + order_id): "
    f"{review_composite_duplicates.sum():,}"
)

print(
    "Distinct (review_id + order_id) combinations: "
    f"{reviews[['review_id', 'order_id']].drop_duplicates().shape[0]:,}"
)


# ============================================================
# 5. Product NULL pattern
# ============================================================

print("\n" + "=" * 80)
print("5. PRODUCT NULL PATTERN")
print("=" * 80)

main_product_null_columns = [
    "product_category_name",
    "product_name_lenght",
    "product_description_lenght",
    "product_photos_qty"
]

all_four_missing = products[
    products[main_product_null_columns]
    .isna()
    .all(axis=1)
]

print(
    f"Products missing all four main metadata columns: "
    f"{len(all_four_missing):,}"
)

for column in main_product_null_columns:
    print(
        f"{column}: "
        f"{products[column].isna().sum():,}"
    )


# ============================================================
# 6. Missing product categories used in actual sales?
# ============================================================

print("\n" + "=" * 80)
print("6. SALES USAGE OF PRODUCTS WITH MISSING CATEGORY")
print("=" * 80)

missing_category_products = set(
    products.loc[
        products["product_category_name"].isna(),
        "product_id"
    ]
)

items_with_missing_category = items[
    items["product_id"].isin(missing_category_products)
]

print(
    "Products with missing category: "
    f"{len(missing_category_products):,}"
)

print(
    "Order-item rows using those products: "
    f"{len(items_with_missing_category):,}"
)

print(
    "Orders affected: "
    f"{items_with_missing_category['order_id'].nunique():,}"
)


# ============================================================
# 7. Translation gaps
# ============================================================

print("\n" + "=" * 80)
print("7. CATEGORY TRANSLATION GAPS")
print("=" * 80)

translated_categories = set(
    translations["product_category_name"]
)

translation_gaps = products[
    products["product_category_name"].notna()
    & ~products["product_category_name"].isin(translated_categories)
]

summary = (
    translation_gaps
    .groupby("product_category_name")
    .size()
    .sort_values(ascending=False)
)

print(summary.to_string())


# ============================================================
# 8. Geolocation city/state conflicts per ZIP prefix
# ============================================================

print("\n" + "=" * 80)
print("8. GEOLOCATION ZIP CONFLICT ANALYSIS")
print("=" * 80)

zip_profile = (
    geo
    .groupby("geolocation_zip_code_prefix")
    .agg(
        Rows=("geolocation_zip_code_prefix", "size"),
        Cities=("geolocation_city", "nunique"),
        States=("geolocation_state", "nunique")
    )
)

print(
    "ZIP prefixes mapped to multiple cities: "
    f"{(zip_profile['Cities'] > 1).sum():,}"
)

print(
    "ZIP prefixes mapped to multiple states: "
    f"{(zip_profile['States'] > 1).sum():,}"
)

print("\nLargest ZIP groups:")

print(
    zip_profile
    .sort_values("Rows", ascending=False)
    .head(10)
    .to_string()
)


# ============================================================
# 9. Review-score aggregate precision
# ============================================================

print("\n" + "=" * 80)
print("9. ORDER-LEVEL REVIEW AVERAGE PRECISION")
print("=" * 80)

review_avg = (
    reviews
    .groupby("order_id")["review_score"]
    .mean()
)

fractional_review_averages = review_avg[
    review_avg % 1 != 0
]

print(
    "Orders whose average review score contains decimals: "
    f"{len(fractional_review_averages):,}"
)

print("\nExamples:")

print(
    fractional_review_averages
    .head(20)
    .to_string()
)


print("\n" + "=" * 80)
print("TARGETED INVESTIGATION COMPLETE")
print("=" * 80)