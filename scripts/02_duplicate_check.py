import pandas as pd
from pathlib import Path

RAW_FOLDER = Path("data/raw")

print("=" * 70)
print("OLIST E-COMMERCE DUPLICATE CHECK")
print("=" * 70)

csv_files = list(RAW_FOLDER.glob("*.csv"))

for file in csv_files:

    print(f"\n{'=' * 20} {file.name} {'=' * 20}")

    df = pd.read_csv(file)

    duplicate_rows = df.duplicated().sum()

    print(f"Total rows: {len(df):,}")
    print(f"Duplicate rows: {duplicate_rows:,}")

    if duplicate_rows == 0:
        print("Status: No complete duplicate rows found.")
    else:
        print("Status: Duplicate rows detected.")

print("\n" + "=" * 70)
print("DUPLICATE CHECK COMPLETED")
print("=" * 70)