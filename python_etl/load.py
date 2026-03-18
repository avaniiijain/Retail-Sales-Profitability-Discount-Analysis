import pandas as pd
import urllib
from sqlalchemy import create_engine, text
from sqlalchemy import Date, String, Integer, Numeric


SERVER   = r"Avani\SQLEXPRESS"
DATABASE = "SuperstoreDB"
CSV_PATH = "C:\\Users\\avani\\Project1\\superstore_clean.csv"

# 1. CREATE DATABASE
# Must connect to master first — you cannot drop/create a database
# while connected to it. master always exists in every SQL Server instance.
print("--- Database Setup ---")

master_params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE=master;"
    f"Trusted_Connection=yes;"
)

master_engine = create_engine(
    f"mssql+pyodbc:///?odbc_connect={master_params}",
    isolation_level="AUTOCOMMIT"    # CREATE/DROP DATABASE cannot run inside
                                    # a transaction — AUTOCOMMIT is required
)

with master_engine.connect() as conn:

    # Drop if exists — force close any active connections first
    # Without SINGLE_USER the drop will fail if SSMS is connected to it
    conn.execute(text(f"""
        IF EXISTS (SELECT name FROM sys.databases WHERE name = '{DATABASE}')
        BEGIN
            ALTER DATABASE {DATABASE} SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
            DROP DATABASE {DATABASE};
        END
    """))

    # Create fresh database
    conn.execute(text(f"CREATE DATABASE {DATABASE}"))

print(f"Database '{DATABASE}' dropped and recreated")


# 1. READ CLEANED CSV
df = pd.read_csv(CSV_PATH, encoding="latin1")
df["order_date"] = pd.to_datetime(df["order_date"])
df["ship_date"]  = pd.to_datetime(df["ship_date"])
df["postal_code"] = df["postal_code"].astype(str).str.zfill(5)
print(f"Rows read from CSV: {len(df):,}")


# 2. CONNECT TO SQL SERVER
params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
)

engine = create_engine(
    f"mssql+pyodbc:///?odbc_connect={params}",
    fast_executemany=True
)

with engine.connect() as conn:
    conn.execute(text("SELECT 1"))
print(f"Connected to: {SERVER} / {DATABASE}")


# 3. LOAD TABLE
dtype_map = {
    "row_id"              : Integer(),
    "order_id"            : String(14),
    "order_date"          : Date(),
    "ship_date"           : Date(),
    "ship_mode"           : String(14),
    "customer_id"         : String(8),
    "customer_name"       : String(22),
    "segment"             : String(11),
    "country"             : String(13),
    "city"                : String(50),
    "state"               : String(20),
    "postal_code"         : String(5),
    "region"              : String(7),
    "product_id"          : String(15),
    "category"            : String(15),
    "sub_category"        : String(11),
    "product_name"        : String(127),
    "sales"               : Numeric(10, 2),
    "quantity"            : Integer(),
    "percentage_discount" : Numeric(5, 2),
    "profit"              : Numeric(10, 2),
}

df.to_sql(
    name      = "superstore_clean",
    con       = engine,
    if_exists = "replace",
    index     = False,
    dtype     = dtype_map
)
print(f"Table loaded: superstore_clean ({len(df):,} rows)")


# 4. DDL — primary key + analytical view
with engine.connect() as conn:

    # Recreate row_id as NOT NULL
    conn.execute(text("""
        ALTER TABLE superstore_clean
        ALTER COLUMN row_id INT NOT NULL
    """))

    # Primary key
    conn.execute(text("""
        ALTER TABLE superstore_clean
        ADD CONSTRAINT PK_superstore PRIMARY KEY (row_id)
    """))

    # Drop view if it already exists
    conn.execute(text("""
        IF OBJECT_ID('vw_superstore', 'V') IS NOT NULL
            DROP VIEW vw_superstore
    """))

    # Analytical view — single source of truth for all queries and Tableau
    conn.execute(text("""
        CREATE VIEW vw_superstore AS
        SELECT
            -- Identifiers
            row_id,
            order_id,
            customer_id,
            customer_name,

            -- Time
            order_date,
            ship_date,
            DATEDIFF(DAY, order_date, ship_date)    AS days_to_ship,
            YEAR(order_date)                        AS order_year,
            DATEPART(QUARTER, order_date)           AS order_quarter,
            MONTH(order_date)                       AS order_month,
            DATENAME(MONTH, order_date)             AS order_month_name,

            -- Geography
            country,
            region,
            state,
            city,
            postal_code,

            -- Customer
            segment,
            ship_mode,

            -- Product
            product_id,
            product_name,
            category,
            sub_category,

            -- Base measures
            sales,
            quantity,
            percentage_discount,
            profit,

            -- Promotion flag: 1 if any discount was applied, else 0
            CASE WHEN percentage_discount > 0
                 THEN 1 ELSE 0
            END                                     AS is_promoted,

            -- Discount bucket for tier analysis
            CASE
                WHEN percentage_discount = 0   THEN 'No Discount'
                WHEN percentage_discount <= 10 THEN 'Low (1-10%)'
                WHEN percentage_discount <= 30 THEN 'Mid (11-30%)'
                WHEN percentage_discount <= 50 THEN 'High (31-50%)'
                ELSE                                'Extreme (>50%)'
            END                                     AS discount_bucket,

            -- Numeric rank for sorting discount buckets in Tableau
            CASE
                WHEN percentage_discount = 0   THEN 1
                WHEN percentage_discount <= 10 THEN 2
                WHEN percentage_discount <= 30 THEN 3
                WHEN percentage_discount <= 50 THEN 4
                ELSE                                5
            END                                     AS discount_bucket_rank,

            -- Implied full price per unit before discount was applied
            -- Formula: sales = unit_price * quantity * (1 - discount/100)
            CAST(ROUND(
                sales / NULLIF(quantity * (1 - percentage_discount / 100.0), 0),
            2) AS DECIMAL(10,2))                     AS unit_price,

            -- Dollar value given away as discount
            CAST(ROUND(
                (sales / NULLIF(1 - percentage_discount / 100.0, 0)) - sales,
            2) AS DECIMAL(12,2))                    AS revenue_impact,

            -- Profit as a fraction of sales — negative means sold at a loss
            CAST(ROUND(profit / NULLIF(sales, 0), 4) AS DECIMAL(10,2))AS contribution_margin,

            -- Human readable profit classification
            CASE
                WHEN profit > 0 THEN 'Profitable'
                WHEN profit = 0 THEN 'Break-Even'
                ELSE                 'Loss'
            END                                     AS profit_flag

        FROM superstore_clean
    """))

    conn.commit()

print("Primary key added: PK_superstore")
print("View created     : vw_superstore")


# 5. VERIFY
with engine.connect() as conn:
    table_rows = conn.execute(text("SELECT COUNT(*) FROM superstore_clean")).scalar()
    view_rows  = conn.execute(text("SELECT COUNT(*) FROM vw_superstore")).scalar()

print(f"\nRows in superstore_clean : {table_rows:,}")
print(f"Rows in vw_superstore    : {view_rows:,}")
print(f"\n{'='*55}")
print(f"  Done. Open SSMS and run DQL on vw_superstore")
print(f"{'='*55}")