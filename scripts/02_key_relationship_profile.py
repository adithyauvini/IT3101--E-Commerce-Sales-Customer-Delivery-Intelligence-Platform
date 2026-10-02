from pathlib import Path
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_FOLDER = PROJECT_ROOT / "data" / "raw"


def load_csv(file_name, columns):
    """Load only required columns to keep memory usage low."""
    return pd.read_csv(
        RAW_FOLDER / file_name,
        usecols=columns,
        low_memory=False
    )


def key_profile(label, df, key_columns):
    print("\n" + "=" * 80)
    print(f"KEY PROFILE: {label}")
    print("=" * 80)

    missing_key_rows = df[key_columns].isna().any(axis=1).sum()

    duplicate_mask = df.duplicated(
        subset=key_columns,
        keep=False
    )

    duplicate_rows = duplicate_mask.sum()

    if duplicate_rows > 0:
        duplicate_groups = (
            df.loc[duplicate_mask]
            .groupby(key_columns, dropna=False)
            .size()
            .shape[0]
        )
    else:
        duplicate_groups = 0

    distinct_keys = df[key_columns].drop_duplicates().shape[0]

    print(f"Rows                 : {len(df):,}")
    print(f"Distinct key values  : {distinct_keys:,}")
    print(f"Missing-key rows     : {missing_key_rows:,}")
    print(f"Duplicate-key rows   : {duplicate_rows:,}")
    print(f"Duplicate key groups : {duplicate_groups:,}")


def foreign_key_profile(
    relationship_name,
    child_df,
    child_column,
    parent_df,
    parent_column
):
    print("\n" + "-" * 80)
    print(f"RELATIONSHIP: {relationship_name}")
    print("-" * 80)

    parent_values = set(
        parent_df[parent_column]
        .dropna()
        .unique()
    )

    child_non_null = child_df[
        child_df[child_column].notna()
    ]

    orphan_mask = ~child_non_null[child_column].isin(parent_values)

    orphan_rows = child_non_null.loc[orphan_mask]

    print(f"Child rows checked : {len(child_non_null):,}")
    print(f"Orphan rows        : {len(orphan_rows):,}")
    print(
        f"Orphan key values  : "
        f"{orphan_rows[child_column].nunique():,}"
    )

    if len(orphan_rows) > 0:
        print("\nExample orphan keys:")

        for value in (
            orphan_rows[child_column]
            .drop_duplicates()
            .head(10)
        ):
            print(f" - {value}")


print("=" * 80)
print("OLIST KEY AND RELATIONSHIP PROFILE")
print("=" * 80)


# -------------------------------------------------------------------
# Load only necessary columns
# -------------------------------------------------------------------

customers = load_csv(
    "olist_customers_dataset.csv",
    [
        "customer_id",
        "customer_unique_id"
    ]
)

orders = load_csv(
    "olist_orders_dataset.csv",
    [
        "order_id",
        "customer_id",
        "order_status",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date"
    ]
)

items = load_csv(
    "olist_order_items_dataset.csv",
    [
        "order_id",
        "order_item_id",
        "product_id",
        "seller_id"
    ]
)

payments = load_csv(
    "olist_order_payments_dataset.csv",
    [
        "order_id",
        "payment_sequential"
    ]
)

reviews = load_csv(
    "olist_order_reviews_dataset.csv",
    [
        "review_id",
        "order_id",
        "review_score"
    ]
)

products = load_csv(
    "olist_products_dataset.csv",
    [
        "product_id",
        "product_category_name"
    ]
)

sellers = load_csv(
    "olist_sellers_dataset.csv",
    [
        "seller_id"
    ]
)

translations = load_csv(
    "product_category_name_translation.csv",
    [
        "product_category_name",
        "product_category_name_english"
    ]
)

geolocation = load_csv(
    "olist_geolocation_dataset.csv",
    [
        "geolocation_zip_code_prefix"
    ]
)


# -------------------------------------------------------------------
# Key profiling
# -------------------------------------------------------------------

key_profile(
    "Customers.customer_id",
    customers,
    ["customer_id"]
)

key_profile(
    "Customers.customer_unique_id",
    customers,
    ["customer_unique_id"]
)

key_profile(
    "Orders.order_id",
    orders,
    ["order_id"]
)

key_profile(
    "Order Items (order_id + order_item_id)",
    items,
    ["order_id", "order_item_id"]
)

key_profile(
    "Payments (order_id + payment_sequential)",
    payments,
    ["order_id", "payment_sequential"]
)

key_profile(
    "Reviews.review_id",
    reviews,
    ["review_id"]
)

key_profile(
    "Reviews.order_id",
    reviews,
    ["order_id"]
)

key_profile(
    "Products.product_id",
    products,
    ["product_id"]
)

key_profile(
    "Sellers.seller_id",
    sellers,
    ["seller_id"]
)

key_profile(
    "Category Translation.product_category_name",
    translations,
    ["product_category_name"]
)


# -------------------------------------------------------------------
# Relationship / orphan profiling
# -------------------------------------------------------------------

foreign_key_profile(
    "Orders -> Customers",
    orders,
    "customer_id",
    customers,
    "customer_id"
)

foreign_key_profile(
    "Order Items -> Orders",
    items,
    "order_id",
    orders,
    "order_id"
)

foreign_key_profile(
    "Order Items -> Products",
    items,
    "product_id",
    products,
    "product_id"
)

foreign_key_profile(
    "Order Items -> Sellers",
    items,
    "seller_id",
    sellers,
    "seller_id"
)

foreign_key_profile(
    "Payments -> Orders",
    payments,
    "order_id",
    orders,
    "order_id"
)

foreign_key_profile(
    "Reviews -> Orders",
    reviews,
    "order_id",
    orders,
    "order_id"
)

# Only non-null product categories should be checked against translation.
product_categories = products[
    products["product_category_name"].notna()
]

foreign_key_profile(
    "Products -> Category Translation",
    product_categories,
    "product_category_name",
    translations,
    "product_category_name"
)


# -------------------------------------------------------------------
# Customer business-key behaviour
# -------------------------------------------------------------------

print("\n" + "=" * 80)
print("CUSTOMER UNIQUE-ID ANALYSIS")
print("=" * 80)

customer_frequency = (
    customers
    .groupby("customer_unique_id")
    .size()
)

print(
    f"Distinct customer_id       : "
    f"{customers['customer_id'].nunique():,}"
)

print(
    f"Distinct customer_unique_id: "
    f"{customers['customer_unique_id'].nunique():,}"
)

print(
    f"Unique customers appearing more than once: "
    f"{(customer_frequency > 1).sum():,}"
)

print(
    f"Maximum customer_id records for one unique customer: "
    f"{customer_frequency.max():,}"
)


# -------------------------------------------------------------------
# Review relationship analysis
# -------------------------------------------------------------------

print("\n" + "=" * 80)
print("REVIEW RELATIONSHIP ANALYSIS")
print("=" * 80)

reviews_per_order = (
    reviews
    .groupby("order_id")
    .size()
)

print(
    f"Orders represented in reviews : "
    f"{reviews['order_id'].nunique():,}"
)

print(
    f"Orders with multiple reviews  : "
    f"{(reviews_per_order > 1).sum():,}"
)

print(
    f"Maximum reviews for one order : "
    f"{reviews_per_order.max():,}"
)


# -------------------------------------------------------------------
# Payment cardinality
# -------------------------------------------------------------------

print("\n" + "=" * 80)
print("PAYMENT CARDINALITY ANALYSIS")
print("=" * 80)

payments_per_order = (
    payments
    .groupby("order_id")
    .size()
)

print(
    f"Orders represented in payments: "
    f"{payments['order_id'].nunique():,}"
)

print(
    f"Orders with multiple payments : "
    f"{(payments_per_order > 1).sum():,}"
)

print(
    f"Maximum payments for one order: "
    f"{payments_per_order.max():,}"
)


# -------------------------------------------------------------------
# Geolocation grain analysis
# -------------------------------------------------------------------

print("\n" + "=" * 80)
print("GEOLOCATION ZIP-PREFIX ANALYSIS")
print("=" * 80)

geo_frequency = (
    geolocation
    .groupby("geolocation_zip_code_prefix")
    .size()
)

print(
    f"Rows                    : "
    f"{len(geolocation):,}"
)

print(
    f"Distinct ZIP prefixes   : "
    f"{geolocation['geolocation_zip_code_prefix'].nunique():,}"
)

print(
    f"ZIP prefixes with >1 row: "
    f"{(geo_frequency > 1).sum():,}"
)

print(
    f"Maximum rows for one ZIP: "
    f"{geo_frequency.max():,}"
)


# -------------------------------------------------------------------
# Order status vs missing lifecycle dates
# -------------------------------------------------------------------

print("\n" + "=" * 80)
print("ORDER STATUS / MISSING-DATE ANALYSIS")
print("=" * 80)

status_summary = (
    orders
    .groupby("order_status")
    .agg(
        Orders=("order_id", "size"),
        MissingApproval=(
            "order_approved_at",
            lambda x: x.isna().sum()
        ),
        MissingCarrierDelivery=(
            "order_delivered_carrier_date",
            lambda x: x.isna().sum()
        ),
        MissingCustomerDelivery=(
            "order_delivered_customer_date",
            lambda x: x.isna().sum()
        )
    )
    .sort_values("Orders", ascending=False)
)

print(status_summary.to_string())


print("\n" + "=" * 80)
print("KEY AND RELATIONSHIP PROFILING COMPLETE")
print("=" * 80)