import pandas as pd
from pathlib import Path

# Location of the raw CSV files
RAW_FOLDER = Path("data/raw")

print("=" * 70)
print("OLIST E-COMMERCE DATA QUALITY CHECK")
print("=" * 70)

# Find all CSV files
csv_files = list(RAW_FOLDER.glob("*.csv"))

# Check every CSV file
for file in csv_files:

    print(f"\n{'=' * 20} {file.name} {'=' * 20}")

    # Read the CSV
    df = pd.read_csv(file)

    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns)}")

    print("\nMissing values:")

    missing = df.isnull().sum()

    # Display only columns containing missing values
    missing_found = False

    for column, count in missing.items():
        if count > 0:
            missing_found = True
            percentage = (count / len(df)) * 100
            print(
                f"  {column}: {count:,} "
                f"({percentage:.2f}%)"
            )

    if not missing_found:
        print("  No missing values found.")

print("\n" + "=" * 70)
print("DATA QUALITY CHECK COMPLETED")
print("=" * 70)