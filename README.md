# The Discount Trap
## Superstore Discount & Profitability Analysis

> *Discounts are buying revenue, not profit.*

An end-to-end Business Intelligence project investigating how discounting affects revenue, profitability, and pricing strategy using **Python, SQL Server, and Tableau**.

**🔗 Tableau Story:**  
https://public.tableau.com/views/Retail_Sales_project/TheDiscountTrap?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

---

# Project Overview

Retail businesses often rely on promotions to increase sales, but aggressive discounting can reduce profitability.

This project analyzes four years of Superstore sales data to determine whether discounts actually improve business performance or simply generate additional revenue at the expense of profit.

The project covers the complete analytics workflow:

- Data cleaning with Python
- ETL pipeline into SQL Server
- Analytical SQL view creation
- Business analysis using T-SQL
- Interactive Tableau dashboard

---

# Business Questions

This project answers four key questions:

1. Do promotions increase profit or only revenue?
2. Which product categories are over-discounted?
3. How price-sensitive are different customer segments?
4. What discount policy would maximize profitability?

---

# Key Finding

| | Full Price | Discounted |
|---|---:|---:|
| Total Profit | $320,987 | -$34,590 |
| Average Order Profit | $66.90 | -$6.66 |
| Loss-Making Orders | 0 | 1,871 |
| Average Contribution Margin | 33.9% | -8.3% |

> Discounts increased revenue, but every loss-making order in the dataset occurred on a discounted transaction.

---

# Tech Stack

| Layer | Technology |
|---|---|
| Programming | Python 3 |
| Data Cleaning | Pandas |
| ETL | SQLAlchemy, pyodbc |
| Database | SQL Server 2022 (Docker) |
| SQL | T-SQL |
| Visualization | Tableau Public |
| Environment | python-dotenv |
| Version Control | Git & GitHub |

---

# Project Architecture

```
Sample_Superstore.csv
        │
        ▼
 Data_prep.py
        │
        ▼
superstore_clean.csv
        │
        ▼
     load.py
        │
        ▼
 SQL Server Database
        │
        ▼
   vw_superstore
        │
        ▼
   SQL Analysis
        │
        ▼
 Tableau Dashboard
```

---

# Repository Structure

```
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
│   ├── promotions.sql
│   ├── over discounted.sql
│   ├── elasticity.sql
│   └── optimisation.sql
│
├── tableau/
│
├── .env.example
├── .gitignore
└── README.md
```

---

# ETL Pipeline

## Step 1 — Data Preparation (`Data_prep.py`)

The raw dataset is cleaned and validated before loading into SQL Server.

### Transformations

- Standardized column names
- Parsed order and ship dates
- Preserved leading zeros in postal codes
- Converted discount values to percentages
- Rounded monetary values
- Standardized categorical values

### Validation Checks

- Duplicate Row IDs
- Missing values
- Invalid shipping dates
- Invalid discount values
- Invalid sales and quantity values

The cleaned dataset is exported as:

```
data/superstore_clean.csv
```

---

## Step 2 — Database Load (`load.py`)

The ETL script automatically:

- Reads SQL credentials from a `.env` file
- Recreates the SQL Server database
- Loads the cleaned dataset
- Creates the primary key
- Builds the analytical view `vw_superstore`
- Verifies successful data load

Database connections are managed securely using environment variables.

---

## Step 3 — Analytical View

The project creates a reusable SQL view:

```
vw_superstore
```

Additional business metrics are calculated inside SQL, including:

| Derived Column | Description |
|---|---|
| days_to_ship | Shipping duration |
| order_year | Order year |
| order_quarter | Order quarter |
| order_month | Order month |
| is_promoted | Promotion flag |
| discount_bucket | Discount tier |
| discount_bucket_rank | Tableau sort order |
| revenue_impact | Revenue lost through discounting |
| contribution_margin | Profit ÷ Sales |
| unit_price | Estimated full unit price |
| profit_flag | Profit / Break-even / Loss |

---

# SQL Analysis

The SQL scripts answer four business questions.

## Promotions vs Profit

Measures whether discounted transactions generate sustainable profit.

---

## Over-Discounted Categories

Identifies categories and sub-categories where discounts consistently destroy margin.

---

## Price Elasticity

Evaluates whether customer segments purchase more units as discounts increase.

---

## Discount Optimization

Simulates different discount thresholds to recommend a more profitable pricing policy.

---

# Tableau Dashboard

The Tableau Story contains five sections:

1. Executive Summary
2. Promotions vs Profit
3. Over-Discounted Categories
4. Price Elasticity by Segment
5. Discount Optimization

---

# Dataset

**Source**

https://www.kaggle.com/datasets/vivek468/superstore-dataset-final

**Rows**

9,994

**Period**

January 2014 – December 2017

**Markets**

United States

---

# Getting Started

## Prerequisites

- Python 3.9+
- Docker Desktop
- SQL Server 2022 Docker container
- ODBC Driver 18 for SQL Server

---

## Installation

Clone the repository:

```bash
git clone https://github.com/avaniiijain/Retail-Sales-Profitability-Discount-Analysis.git

cd Retail-Sales-Profitability-Discount-Analysis
```

Create a `.env` file using `.env.example`:

```text
SQL_SERVER=127.0.0.1,1433
SQL_DATABASE=SuperstoreDB
SQL_USERNAME=sa
SQL_PASSWORD=your_password
SQL_DRIVER=ODBC Driver 18 for SQL Server
```

Run the ETL pipeline:

```bash
python python_etl/Data_prep.py

python python_etl/load.py
```

---

# Author

**Avani Jain**

MS in Business Analytics  
University of Massachusetts Boston

LinkedIn:

GitHub: https://github.com/avaniiijain
