# The Discount Trap

### *When More Sales Lead to Less Profit*

> **An end-to-end retail pricing analytics project that evaluates whether promotional discounts create sustainable business value and recommends a more profitable pricing strategy through SQL-driven analysis.**

<p align="center">
  <b>Python ETL</b> • 🗄️ <b>SQL Server Analytics</b> • <b>Tableau Storytelling</b> • <b>Docker</b>
</p>

<p align="center">
  <a href="https://public.tableau.com/views/Retail_Sales_project/TheDiscountTrap?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link">
    View the Tableau Story
  </a>
</p>

---

## Project Overview

Retail businesses frequently use discounts to attract customers and increase sales. However, higher sales activity does not necessarily result in stronger profitability.

This project investigates whether promotional discounts create sustainable financial value or reduce margins through excessive discounting.

The project follows a complete analytics workflow:

- Data validation and cleaning with Python
- ETL pipeline into SQL Server
- Analytical view creation
- Business analysis using T-SQL
- Discount-policy simulation
- Interactive storytelling with Tableau

---

## Business Questions

The investigation was structured around four sequential business questions, with each answer guiding the next stage of analysis.

| Stage | Business Question |
|---|---|
| 📈 **Stage 1** | Do promotions actually increase profit or just revenue? |
| 📦 **Stage 2** | Which product categories are over-discounted? |
| 👥 **Stage 3** | How do different customer segments respond to discounting? |
| 💡 **Stage 4** | What discount strategy maximizes profitability while protecting margins? |

---

## Key Findings

- Discounted transactions generated strong sales activity but weakened overall profitability.
- Promotional losses were concentrated within specific categories and sub-categories.
- Profitability declined substantially as discount depth increased.
- Customer segments showed broadly similar patterns across discount levels.
- Product economics and discount depth were more important than customer segment.
- The analysis supported a hybrid strategy combining tailored sub-category caps with a broader company-wide discount limit.

Detailed findings and visualizations are available in the Tableau Story and SQL scripts.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Programming | Python 3 |
| Data Preparation | pandas |
| ETL | SQLAlchemy, pyodbc |
| Database | SQL Server 2022 |
| Infrastructure | Docker |
| Analysis | T-SQL |
| Visualization | Tableau Public |
| Configuration | python-dotenv |
| Version Control | Git and GitHub |

---

## Project Architecture

```text
┌──────────────────────────────┐
│ Raw Superstore Dataset       │
│ Sample_Superstore.csv        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Python Data Preparation      │
│ Data_prep.py                 │
│                              │
│ • Cleaning                   │
│ • Validation                 │
│ • Transformation             │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Cleaned Dataset              │
│ superstore_clean.csv         │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Python ETL Pipeline          │
│ load.py                      │
│                              │
│ • Database creation          │
│ • Table loading              │
│ • SQL view creation          │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ SQL Server Analytics Layer   │
│                              │
│ superstore_clean             │
│ vw_superstore                │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ T-SQL Business Analysis      │
│                              │
│ • Promotional performance    │
│ • Product risk analysis      │
│ • Segment response           │
│ • Discount simulations       │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Tableau Storytelling         │
│                              │
│ Insights, trends and         │
│ pricing recommendations      │
└──────────────────────────────┘
```

---

## Repository Structure

```text
Retail-Sales-Profitability-Discount-Analysis/
│
├── data/
│   ├── Sample_Superstore.csv
│   └── superstore_clean.csv
│
├── python_etl/
│   ├── Data_prep.py
│   └── load.py
│
├── sql/
│   ├── 01_promotional_performance.sql
│   ├── 02_over_discounted_products.sql
│   ├── 03_segment_discount_response.sql
│   └── 04_discount_optimization_strategy.sql
│
├── tableau/
│   └── dashboard_link.txt
│
├── .env.example
├── .gitignore
└── README.md
```

---

## ETL Pipeline

### 1. Data Preparation

`Data_prep.py` loads the raw dataset, validates its quality, performs the required transformations, and exports a cleaned CSV.

Main tasks include:

- Standardizing column names
- Parsing order and shipping dates
- Preserving leading zeros in postal codes
- Converting discounts into percentages
- Standardizing categorical values
- Checking duplicates, nulls, invalid dates, discounts, sales, and quantities

Output:

```text
data/superstore_clean.csv
```

### 2. SQL Server Load

`load.py`:

- Reads database credentials from the `.env` file
- Creates the SQL Server database
- Loads the cleaned dataset
- Assigns SQL data types
- Adds a primary key
- Creates the analytical view
- Verifies the loaded table and view

### 3. Analytical View

The reusable `vw_superstore` view provides a consistent analytical layer for SQL and Tableau.

It includes derived fields such as:

| Field | Purpose |
|---|---|
| `days_to_ship` | Shipping duration |
| `order_year` | Year-level analysis |
| `order_quarter` | Quarterly analysis |
| `order_month` | Monthly analysis |
| `is_promoted` | Identifies discounted transactions |
| `discount_bucket` | Groups transactions by discount depth |
| `discount_bucket_rank` | Maintains the correct discount-tier order |
| `unit_price` | Estimates full unit price |
| `revenue_impact` | Estimates revenue given away through discounting |
| `contribution_margin` | Measures profit relative to sales |
| `profit_flag` | Classifies profitable, break-even, or loss records |

---

## SQL Analysis

### Stage 1: Promotional Performance

Compares discounted and full-price transactions to determine whether promotions improve profitability or primarily increase revenue.

The analysis includes:

- Overall promoted versus non-promoted performance
- Category-level comparison
- Performance over time
- Overall profit impact of discounted sales

### Stage 2: Over-Discounted Products

Identifies where promotional losses are concentrated.

The analysis includes:

- Discounted sub-category profitability scorecard
- Profitability by discount depth
- High-risk sub-category screening
- Category-level discount efficiency

High-risk sub-categories are identified using:

- Average promoted discount above 20%
- Loss rate above 30%
- At least 30 promoted sales records

### Stage 3: Customer Segment Response

Evaluates whether Consumer, Corporate, and Home Office customers perform differently under discounting.

The analysis includes:

- Segment profitability across discount tiers
- Distribution of sales records and units across discount levels
- Segment profitability ranking within each tier

This is a descriptive analysis of observed customer activity and profitability. It does not estimate causal price elasticity.

### Stage 4: Discount Optimization Strategy

Translates the findings into actionable pricing recommendations.

The analysis includes:

- Discount-cap selection for high-risk sub-categories
- Tailored discount-policy simulation
- Uniform 30% discount-cap simulation
- Category-level policy comparison

SQL views are used to store reusable simulation outputs and avoid recalculating dependent results.

Created views include:

```text
vw_high_risk_discount_caps
vw_tailored_discount_policy
vw_uniform_discount_policy
```

---

## Tableau Story

The Tableau Story presents the SQL analysis through interactive business visualizations.

It covers:

1. Executive overview
2. Promotions versus profit
3. Over-discounted products
4. Customer segment response
5. Discount optimization and recommendations

**[Open the Tableau Story](https://public.tableau.com/views/Retail_Sales_project/TheDiscountTrap?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**

---

## Dataset

**Source:** [Superstore Dataset on Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)

| Attribute | Value |
|---|---|
| Records | 9,994 |
| Period | January 2014–December 2017 |
| Market | United States |
| Categories | Furniture, Office Supplies, Technology |

---

## Getting Started

### Prerequisites

- Python 3.9+
- Docker Desktop
- SQL Server 2022 Docker image
- Microsoft ODBC Driver 18 for SQL Server

### Clone the Repository

```bash
git clone https://github.com/avaniiijain/Retail-Sales-Profitability-Discount-Analysis.git
cd Retail-Sales-Profitability-Discount-Analysis
```

### Create a Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### Install Dependencies

```bash
pip install pandas sqlalchemy pyodbc python-dotenv
```

### Configure the Database Connection

Create a `.env` file based on `.env.example`:

```env
SQL_SERVER=127.0.0.1,1433
SQL_DATABASE=SuperstoreDB
SQL_USERNAME=sa
SQL_PASSWORD=your_password_here
SQL_DRIVER=ODBC Driver 18 for SQL Server
```

### Run the ETL Pipeline

```bash
python python_etl/Data_prep.py
python python_etl/load.py
```

### Run the SQL Scripts

Execute the SQL files in order:

```text
01_promotional_performance.sql
02_over_discounted_products.sql
03_segment_discount_response.sql
04_discount_optimization_strategy.sql
```

---

## Simulation Assumptions

The discount-policy analysis is a controlled what-if simulation.

It assumes:

- The same transactions and quantities are retained after repricing
- Estimated product cost remains unchanged
- Discounts above the proposed cap are reduced
- Transactions already within the cap remain unchanged

The simulation evaluates potential financial outcomes under these assumptions and does not predict changes in customer demand.

---

## Author

**Avani Jain**  
MS in Business Analytics  
University of Massachusetts Boston

[LinkedIn](https://www.linkedin.com/in/avani-jain-893628254)  
[GitHub](https://github.com/avaniiijain)
