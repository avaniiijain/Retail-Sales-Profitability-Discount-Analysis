# Project : Superstore Discount & Profitability Analysis
# Purpose : Load raw CSV, clean, validate, and export cleaned dataset for analysis

import pandas as pd
import os


# 1. LOAD RAW DATA
df = pd.read_csv("Sample_Superstore.csv", encoding="latin1")
print(f"Rows loaded: {len(df):,}")


# 2. COLUMN NAMES: strip whitespace, lowercase, replace spaces/hyphens with underscores
df.columns = (
    df.columns
    .str.strip()
    .str.lower()
    .str.replace(" ", "_")
    .str.replace("-", "_")
)


# 3. DATA TYPES
df["order_date"] = pd.to_datetime(df["order_date"], format="%m/%d/%Y")
df["ship_date"]  = pd.to_datetime(df["ship_date"],  format="%m/%d/%Y")

# Postal code: read as int by pandas, must restore leading zeros
df["postal_code"] = df["postal_code"].astype(str).str.zfill(5)


# 4. DUPLICATE CHECK
dupes = df.duplicated(subset="row_id").sum()
print(f"Duplicate rows: {dupes}")


# 5. NULL CHECK
nulls = df.isnull().sum()
print(f"Nulls per column:\n{nulls[nulls > 0]}")


# 6. DOMAIN VALIDATION
# Order / Customer ID consistency  —  same order should map to one customer
inconsistent_orders = (
    df.groupby("order_id")["customer_id"]
    .nunique()
)
print(f"Orders with >1 customer_id: {(inconsistent_orders > 1).sum()}") 

# Ship date must be on or after order date
bad_dates = (df["ship_date"] < df["order_date"]).sum()
print(f"Rows where ship_date < order_date: {bad_dates}")

# Discount must be between 0 and 1
bad_discount = ((df["discount"] < 0) | (df["discount"] > 1)).sum()
print(f"Rows with discount outside [0, 1]: {bad_discount}") 

# Sales and quantity must be positive
print(f"Rows with sales <= 0   : {(df['sales'] <= 0).sum()}")
print(f"Rows with quantity <= 0: {(df['quantity'] <= 0).sum()}")


# 7. TRANSFORMATIONS

# Discount: convert from decimal to percentage
df.rename(columns={"discount": "percentage_discount"}, inplace=True)
df["percentage_discount"] = (df["percentage_discount"] * 100).round(2)

# Profit: round to 2 decimal places
df["profit"] = df["profit"].round(2)


# 8. STANDARDISE CATEGORICAL CASING

cat_cols = ["segment", "category", "sub_category", "region",
            "ship_mode", "country", "state", "city"]

for col in cat_cols:
    df[col] = df[col].str.strip().str.title()


# 9. SUMMARY
print(f"\n--- Clean Dataset Summary ---")
print(f"Rows            : {len(df):,}")
print(f"Date range      : {df['order_date'].min().date()} → {df['order_date'].max().date()}")
print(f"Segments        : {sorted(df['segment'].unique())}")
print(f"Categories      : {sorted(df['category'].unique())}")
print(f"Regions         : {sorted(df['region'].unique())}")
print(f"Discount range  : {df['percentage_discount'].min()} – {df['percentage_discount'].max()}")
print(f"Profit range    : ${df['profit'].min():,.2f} – ${df['profit'].max():,.2f}")
print(f"Loss-making rows: {(df['profit'] < 0).sum():,} ({(df['profit'] < 0).mean()*100:.1f}%)")


# 10. EXPORT
OUTPUT_PATH = "C:\\Users\\avani\\Project1\\superstore_clean.csv"

if os.path.exists(OUTPUT_PATH):
    os.remove(OUTPUT_PATH)

df.to_csv(OUTPUT_PATH, index=False)
print(f"\nSaved to: {OUTPUT_PATH}")
