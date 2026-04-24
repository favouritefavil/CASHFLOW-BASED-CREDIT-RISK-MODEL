# Data Dictionary

## Overview

The database consists of three tables linked by `customer_id`. Together they represent the full borrower profile, monthly cashflow behavior, and loan repayment outcome for each applicant.

## Table Relationships

```
customers (1)
    |
    |---- cashflows (many)   up to 12 rows per customer, one per month
    |
    └---- loans (1)          one loan record per customer
```

`customer_id` is the primary key in `customers` and a foreign key in both `cashflows` and `loans`.

## Table 1: customers

Stores static borrower profile information. One row per borrower.

| Column | Type | Description | Example |
|---|---|---|---|
| `customer_id` | VARCHAR(20) | Unique borrower identifier | CUS00001 |
| `age` | INT | Borrower age | 32 |
| `employment_type` | VARCHAR(20) | Income source category | salary / business / mixed |
| `monthly_income` | DECIMAL(12,2) | Declared average monthly income | 185000.00 |
| `income_stability_score` | DECIMAL(5,3) | Income consistency score on a 0 to 1 scale | 0.826 |
| `rent_amount` | DECIMAL(12,2) | Monthly rent being financed | 55000.00 |
| `location_type` | VARCHAR(20) | Borrower location classification | urban / semi-urban / rural |

Notes:
- `income_stability_score`: 1.0 means perfectly stable income; 0.0 means highly volatile income
- `employment_type = 'mixed'` indicates both salary and business income sources

## Table 2: cashflows

Stores monthly bank statement behavior. Up to 12 rows per borrower.

| Column | Type | Description | Example |
|---|---|---|---|
| `customer_id` | VARCHAR(20) | Links to customers table | CUS00001 |
| `month` | INT | Month number, 1 is the earliest | 1 |
| `inflow_amount` | DECIMAL(12,2) | Total money received that month | 134070.17 |
| `outflow_amount` | DECIMAL(12,2) | Total money spent that month | 106236.62 |
| `ending_balance` | DECIMAL(12,2) | Account balance at end of month | 312667.68 |
| `num_transactions` | INT | Number of individual transactions | 15 |
| `inflow_source_type` | VARCHAR(20) | Classification of income source | salary / business_sales / mixed |

Notes:
- `inflow_amount` is the sum of all credit entries for the month
- `outflow_amount` is the sum of all debit entries for the month
- `ending_balance` is the closing balance from the last statement entry of the month

## Table 3: loans

Stores loan details and repayment outcomes. One row per loan.

| Column | Type | Description | Example |
|---|---|---|---|
| `loan_id` | VARCHAR(20) | Unique loan identifier | LN000001 |
| `customer_id` | VARCHAR(20) | Links to customers table | CUS00001 |
| `loan_amount` | NUMERIC | Total rent amount financed | 328000 |
| `repayment_months` | INT | Loan duration in months | 8 |
| `repayment_status` | VARCHAR(20) | Payment outcome | paid_on_time / late / default |
| `days_past_due` | INT | Days delayed beyond due date | 0 |
| `default_flag` | INT | Target variable: 0 means repaid, 1 means defaulted | 0 |
| `risk_score` | NUMERIC | Pre-computed reference risk score | 59.88 |

Notes:
- `default_flag` is what the machine learning model is trained to predict
- `days_past_due` of 90 or more is classified as default in this system
- `repayment_status = 'late'` with `days_past_due` below 90 is not counted as default

## SQL Views

Three views are created on top of the tables to prepare data for analysis:

| View | Source Tables | Output |
|---|---|---|
| `customer_cashflow_summary` | cashflows | Aggregated monthly metrics per borrower: avg_inflow, avg_outflow, avg_net_cashflow, avg_expense_ratio, avg_balance, inflow_volatility |
| `rent_burden` | customers | Rent-to-income ratio per borrower |
| `model_dataset` | All three tables and both views | Unified 18-column analysis-ready dataset loaded directly into Python |

## Engineered Features (computed in Python)

These four features are derived from the `model_dataset` view in the Python notebook:

| Feature | Formula | Risk Role |
|---|---|---|
| `net_cashflow_ratio` | avg_net_cashflow divided by avg_inflow | Income retention signal |
| `financial_pressure` | average of avg_expense_ratio and rent_to_income_ratio | Combined spending and rent burden |
| `liquidity_strength` | avg_balance divided by avg_inflow | Financial buffer relative to income |
| `stability_score` | income_stability_score divided by (1 plus inflow_volatility divided by avg_inflow) | Income reliability adjusted for actual volatility |

## Dataset Summary

| Metric | Value |
|---|---|
| Total borrowers | 2,000 |
| Cashflow records | 24,000 (12 months x 2,000 borrowers) |
| Loan records | 2,000 |
| Overall default rate | 11.55% |
| Salary earner default rate | 6.8% |
| Business owner default rate | 17.9% |
| Mixed income default rate | 13.6% |
