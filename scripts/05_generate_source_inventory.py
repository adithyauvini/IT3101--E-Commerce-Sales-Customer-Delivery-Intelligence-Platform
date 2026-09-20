import pandas as pd
from pathlib import Path

RAW_DIR = Path("data/raw")
OUTPUT_FILE = Path("references/source_inventory.md")

files = sorted(RAW_DIR.glob("*.csv"))

print("=" * 70)
print("SOURCE INVENTORY GENERATION")
print("=" * 70)

inventory = []

for file in files:

    print(f"\nProcessing: {file.name}")

    df = pd.read_csv(file)

    rows, columns = df.shape

    missing_total = int(df.isna().sum().sum())

    missing_columns = int((df.isna().sum() > 0).sum())

    duplicate_rows = int(df.duplicated().sum())

    inventory.append({
        "file": file.name,
        "rows": rows,
        "columns": columns,
        "missing_values": missing_total,
        "columns_with_missing": missing_columns,
        "duplicate_rows": duplicate_rows
    })

    print(f"Rows: {rows:,}")
    print(f"Columns: {columns}")
    print(f"Missing values: {missing_total:,}")
    print(f"Columns with missing values: {missing_columns}")
    print(f"Complete duplicate rows: {duplicate_rows:,}")


# ---------------------------------------------------------
# Create Markdown document
# ---------------------------------------------------------

lines = []

lines.append("# Olist E-Commerce Data Source Inventory\n")
lines.append(
    "This document records the structure and basic data-quality "
    "characteristics of the original Olist CSV source files. "
    "The raw files are preserved without modification.\n"
)

lines.append("## Source Files\n")

lines.append(
    "| File | Rows | Columns | Missing Values | "
    "Columns With Missing Values | Complete Duplicate Rows |"
)
lines.append("|---|---:|---:|---:|---:|---:|")

for item in inventory:

    lines.append(
        f"| `{item['file']}` | "
        f"{item['rows']:,} | "
        f"{item['columns']} | "
        f"{item['missing_values']:,} | "
        f"{item['columns_with_missing']} | "
        f"{item['duplicate_rows']:,} |"
    )


# ---------------------------------------------------------
# Add detailed column information
# ---------------------------------------------------------

lines.append("\n## Column Details\n")

for file in files:

    df = pd.read_csv(file)

    lines.append(f"\n### `{file.name}`\n")

    lines.append("| Column | Data Type | Missing Values |")
    lines.append("|---|---|---:|")

    for column in df.columns:

        dtype = str(df[column].dtype)
        missing = int(df[column].isna().sum())

        lines.append(
            f"| `{column}` | `{dtype}` | {missing:,} |"
        )


# ---------------------------------------------------------
# Save document
# ---------------------------------------------------------

OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

OUTPUT_FILE.write_text(
    "\n".join(lines),
    encoding="utf-8"
)

print("\n" + "=" * 70)
print("SOURCE INVENTORY CREATED")
print("=" * 70)

print(f"\nOutput file:")
print(OUTPUT_FILE)