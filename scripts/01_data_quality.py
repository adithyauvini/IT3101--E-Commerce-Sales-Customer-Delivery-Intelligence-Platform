from pathlib import Path
import pandas as pd


# ---------------------------------------------------------
# Project paths
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_FOLDER = PROJECT_ROOT / "data" / "raw"


# ---------------------------------------------------------
# Expected source files
# ---------------------------------------------------------

SOURCE_FILES = [
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
]


print("=" * 80)
print("OLIST SOURCE DATA QUALITY PROFILE")
print("=" * 80)

print(f"\nRaw data folder:\n{RAW_FOLDER}\n")


# ---------------------------------------------------------
# Verify files
# ---------------------------------------------------------

missing_files = [
    file_name
    for file_name in SOURCE_FILES
    if not (RAW_FOLDER / file_name).exists()
]

if missing_files:
    print("ERROR: The following source files are missing:")

    for file_name in missing_files:
        print(f" - {file_name}")

    raise SystemExit(1)


print(f"All {len(SOURCE_FILES)} expected CSV files were found.")


# ---------------------------------------------------------
# Profile each dataset
# ---------------------------------------------------------

for file_name in SOURCE_FILES:

    file_path = RAW_FOLDER / file_name

    print("\n" + "=" * 80)
    print(f"FILE: {file_name}")
    print("=" * 80)

    try:
        df = pd.read_csv(
            file_path,
            low_memory=False
        )

    except Exception as error:
        print(f"ERROR reading file: {error}")
        continue

    # Basic information
    print(f"Rows       : {len(df):,}")
    print(f"Columns    : {len(df.columns):,}")
    print(f"Duplicates : {df.duplicated().sum():,}")

    # Column names
    print("\nColumns:")
    for column in df.columns:
        print(f" - {column}")

    # Data types
    print("\nDetected Data Types:")
    for column, dtype in df.dtypes.items():
        print(f" - {column}: {dtype}")

    # Missing values
    null_counts = df.isna().sum()
    null_counts = null_counts[null_counts > 0]

    print("\nMissing Values:")

    if null_counts.empty:
        print(" None")
    else:
        for column, count in null_counts.items():

            percentage = (count / len(df)) * 100

            print(
                f" - {column}: "
                f"{count:,} "
                f"({percentage:.2f}%)"
            )

    # Free memory before loading next file
    del df


print("\n" + "=" * 80)
print("DATA QUALITY PROFILING COMPLETE")
print("=" * 80)