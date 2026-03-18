# The Discount Trap
### Superstore Discount & Profitability Analysis

> *Discounts are buying revenue, not profit.*

An end-to-end analytics project investigating whether Superstore's discount strategy is growing the business — or eroding it. Built across Python, SQL Server, and Tableau.

**[View the Tableau Story on Tableau Public →](#)**

---

## The Problem

The sales team believes discounts drive growth. Revenue is up. But is profit following?

This project answers four questions:

1. Do promotions actually increase profit or just revenue?
2. Which product categories are over-discounted?
3. What is the price elasticity of different customer segments?
4. How can discount depth be optimised to maximise contribution margin?

---

## The Headline Finding

| | Full Price | Discounted |
|---|---|---|
| **Total Profit** | $320,987 | -$34,590 |
| **Avg Order Profit** | $66.90 | -$6.66 |
| **Loss-Making Orders** | 0 | 1,871 |
| **Avg Contribution Margin** | 33.9% | -8.3% |

> **Every single loss-making order in 4 years came from a discounted transaction.**
> Capping discounts at 30% would have recovered **$124,006 in profit** without eliminating a single full-price customer.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data Cleaning | Python 3, pandas |
| Database Load | SQLAlchemy, pyodbc (ODBC Driver 17) |
| Database & Analysis | SQL Server Express, T-SQL |
| Visualisation | Tableau Desktop (Free) |
| Publishing | Tableau Public |

---

## Repository Structure

```
superstore-discount-profitability/
│
├── data/
│   └── Sample_Superstore.csv          # Raw dataset from Kaggle
│
├── python_etl/
│   ├── 01_clean.py                    # Clean, validate, export CSV
│   └── 02_load_to_sql.py             # Create DB, load table, build view
│
├── sql/
│   ├── 00_create_db_and_view.sql      # DDL — SuperstoreDB + vw_superstore
│   ├── 01_promotions_vs_profit.sql    # Q1 analysis
│   ├── 02_over_discounted_categories.sql  # Q2 analysis
│   ├── 03_price_elasticity_by_segment.sql # Q3 analysis
│   └── 04_optimise_discount_depth.sql # Q4 analysis + policy simulation
│
└── tableau/
    └── the_discount_trap_link.txt     # Tableau Public URL
```

---

## Pipeline

### Step 1 — Clean (`python_etl/01_clean.py`)

Loads the raw CSV, runs validation checks, applies transformations, and exports `superstore_clean.csv`.

**Transformations:**
- Column names normalised (lowercase, underscores)
- `order_date` and `ship_date` parsed to datetime
- `postal_code` zero-padded to 5 digits
- `discount` renamed to `percentage_discount`, multiplied by 100
- All categorical columns standardised to Title Case

**Validation (all passed):**
- Duplicate `row_id` — 0
- Null values — 0
- Ship date before order date — 0
- Discount outside [0, 1] — 0

### Step 2 — Load (`python_etl/02_load_to_sql.py`)

Connects to SQL Server Express via SQLAlchemy + pyodbc. Creates `SuperstoreDB`, loads `superstore_clean`, adds primary key, and builds the analytical view `vw_superstore`.

### Step 3 — Analytical View (`sql/00_create_db_and_view.sql`)

`vw_superstore` is the single source of truth for all queries and Tableau. Key derived columns:

| Column | Logic |
|---|---|
| `is_promoted` | 1 if discount > 0, else 0 |
| `discount_bucket` | No Discount / Low (1-10%) / Mid (11-30%) / High (31-50%) / Extreme (>50%) |
| `revenue_impact` | Dollar value given away as discount |
| `contribution_margin` | `profit / sales` — negative means sold at a loss |
| `unit_price` | `sales / (quantity × (1 - discount/100))` |
| `profit_flag` | Profitable / Break-Even / Loss |

---

## SQL Analysis

### Q1 — Promotions vs Profit
Every loss came from a discounted order. Promoted orders average **-$6.66 profit** vs **+$66.90** for full-price. The gap widens year over year.

### Q2 — Over-Discounted Categories
- **Tables** — 63.6% loss rate
- **Bookcases** — 47.8% loss rate
- **Binders** — highest avg discount at 37.2%, $128K in revenue given away

### Q3 — Price Elasticity by Segment
No segment increases volume at deeper discounts. Volume is flat or falling at every tier above Mid, confirming all three segments are **inelastic** to discounting. Corporate and Home Office at Extreme discount lose over **$1 per dollar of revenue**.

### Q4 — Discount Optimisation
| Discount Tier | Margin | Loss Rate |
|---|---|---|
| No Discount | 29.5% | 0% |
| Low (1–10%) | ~14.7% | ~2% |
| Mid (11–30%) | 9.1% | ~8% |
| High (31–50%) | -24.8% | 91.6% |
| Extreme (>50%) | -119.2% | **100%** |

---

## Recommended Caps

| Category | Cap | Rationale |
|---|---|---|
| Furniture | **20%** | Tables and Bookcases destroy margin at any discount above Low |
| Office Supplies | **30%** | Binders over-discounted at 37.2% avg |
| Technology | **30%** | Machines require closer monitoring |

---

## Tableau Story — *The Discount Trap*

5 story points, each with an action filter and a one-line caption:

| # | Story Point | Caption |
|---|---|---|
| 1 | Executive Summary | *Discounts are buying revenue, not profit.* |
| 2 | Do Promotions Increase Profit or Revenue? | *Every loss in this dataset came from a discounted order.* |
| 3 | Which Categories Are Over-Discounted? | *Tables and Bookcases lose money on more than half their discounted orders.* |
| 4 | Price Elasticity by Segment | *No segment buys more at deeper discounts — volume is flat, margin is not.* |
| 5 | Optimise Discount Depth | *A 30% cap recovers $124K without eliminating a single profitable order.* |

---

## Dataset

- **Source:** [Sample Superstore — Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)
- **Rows:** 9,994
- **Date range:** January 2014 – December 2017
- **Scope:** US retail orders across Furniture, Office Supplies, and Technology
