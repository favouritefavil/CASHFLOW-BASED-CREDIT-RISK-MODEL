# Cashflow-Based Credit Scoring Model | Rent Financing Startup

**Built a complete credit risk assessment system from scratch using only bank transaction data, with zero access to credit bureau information.**

## Project Overview

A rent financing startup pays rent upfront on behalf of tenants, who then repay in monthly instalments. The core business problem: how do you decide who to lend to when no credit history exists?

This project answers that question by building a full credit scoring pipeline using bank statement cashflow data as the primary risk signal, covering data engineering, feature engineering, scorecard modeling, machine learning, and an operational Excel decision system.

| | |
|---|---|
| **Domain** | Credit Risk, Alternative Data, Fintech Lending |
| **Tools** | PostgreSQL, Python, Excel |
| **Dataset** | 2,000 borrowers, 12 months of cashflow data, loan repayment outcomes |
| **Status** | Complete: EDA, Feature Engineering, Scorecard, ML Model, Dashboard |

## The Business Problem

Traditional credit scoring fails for this borrower population because:

- No credit history: most borrowers have never taken a formal loan
- No verified debt records: existing obligations cannot be confirmed
- Irregular income: especially for business owners and traders
- No bureau coverage: many financially active people are credit-invisible

The startup needed a risk assessment system built entirely from alternative data.

## The Solution

Replace the credit score with cashflow intelligence: four behavioral risk features engineered directly from bank transaction data.

| Feature | What It Measures | Risk Role |
|---|---|---|
| `stability_score` | Income consistency adjusted for actual volatility | Strongest protective factor |
| `financial_pressure` | Combined spending rate and rent burden | Strongest risk driver |
| `liquidity_strength` | Account buffer relative to monthly income | Financial resilience |
| `net_cashflow_ratio` | Fraction of income retained after expenses | Income headroom |

These four features feed into two complementary models:
- A weighted scorecard (0 to 100 scale) for transparent, explainable decisions
- A logistic regression model for probabilistic default prediction

## Repository Structure

```
cashflow-credit-scoring-rent-financing/
│
├── README.md
│
├── sql/
│   ├── 01_table_creation.sql
│   ├── 02_data_validation.sql
│   └── 03_views.sql
│
├── notebooks/
│   └── EXPLORATORY_DATA_ANALYSIS.ipynb
│
├── excel/
│   └── CREDIT_SCORECARD_RISK_SCORING.xlsx
│
├── data/
│   └── data_dictionary.md
│
└── assets/
    └── dashboard_preview.png
```

## Technical Pipeline

```
PostgreSQL              Python (Jupyter)              Excel
Table creation     -->  Load model_dataset view  -->  RAW SCORECARD sheet
Data validation         EDA and correlations          CREDIT RISK SCORECARD
SQL Views (3)           Feature engineering           MACHINE LEARNING OUTPUT
  cashflow summary      Scorecard modeling            ANALYSIS
  rent burden           Logistic Regression           DASHBOARD
  model_dataset         Model evaluation              APPLICATION VIEW
                        Full dataset prediction
```

## Key Results

### Borrower Portfolio Composition

| Segment | Count | Share | Default Rate |
|---|---|---|---|
| Salary Earners | 987 | 49% | 6.8% |
| Business Owners | 610 | 30% | 17.9% |
| Mixed Income | 403 | 20% | 13.6% |
| **Total** | **2,000** | **100%** | **11.55%** |

### Scorecard Risk Distribution

| Risk Band | Score Range | Borrowers | Decision |
|---|---|---|---|
| Low Risk | 71 to 100 | 657 (33%) | Approve |
| Medium Risk | 41 to 70 | 1,183 (59%) | Manual Review |
| High Risk | 0 to 40 | 160 (8%) | Reject |

### Machine Learning Model Performance

| Metric | Value | Interpretation |
|---|---|---|
| AUC Score | 0.597 | Better than random; meaningful signal |
| Recall (Default class) | 0.58 | Catches 58% of actual defaulters |
| Precision (Default class) | 0.16 | High false-alarm rate; used as second opinion |
| Overall Accuracy | 61% | Model used alongside scorecard, not standalone |

### Model Coefficient Ranking (Logistic Regression)

| Feature | Coefficient | Effect |
|---|---|---|
| `stability_score` | -1.92 | Strongest default protector |
| `net_cashflow_ratio` | -1.15 | Strong income retention signal |
| `liquidity_strength` | -0.16 | Mild buffer protection |
| `financial_pressure` | +1.12 | Strongest risk driver |

### Scorecard vs ML Agreement

| Scorecard Band | ML Non-Default | ML Default | Decision |
|---|---|---|---|
| Low Risk | 175 | 0 | Auto-Approve (100% agreement) |
| High Risk | 0 | 48 | Auto-Reject (100% agreement) |
| Medium Risk | 178 | 199 | Manual Review required |

## Key Analytical Insights

**1. No single variable predicts default reliably**
The strongest individual correlation with default_flag was only 0.14. This confirmed that a multi-feature composite model was necessary because single-variable thresholds do not work on their own.

**2. Income stability is the most important protective factor**
Both the scorecard (35% weight) and the ML model (-1.92 coefficient) independently confirmed stability as the dominant risk signal. How consistently income arrives matters more than how much arrives.

**3. Business owners carry higher risk but not because they are irresponsible**
The 17.9% default rate among business owners versus 6.8% for salary earners is primarily driven by income volatility. The stability score accounts for this by penalizing actual cashflow volatility regardless of declared income type.

**4. Account balance alone is misleading**
Defaulters in the dataset held a slightly higher average balance than non-defaulters (537,554 vs 528,730). Raw balance without income context is not a reliable risk signal. Liquidity strength, which expresses balance relative to income, corrects this.

**5. The Medium Risk zone is where real judgment happens**
55% of borrowers fell into Medium Risk. The two models disagreed on 377 of these borrowers, which correctly reflects genuine borrower ambiguity rather than a modeling error.

## Feature Engineering Details

All four features were computed in Python from raw SQL-aggregated cashflow metrics:

```python
# Net Cashflow Ratio: income retained after expenses
df['net_cashflow_ratio'] = df['avg_net_cashflow'] / df['avg_inflow']

# Financial Pressure: combined spending and rent burden
df['financial_pressure'] = (df['avg_expense_ratio'] + df['rent_to_income_ratio']) / 2

# Liquidity Strength: buffer relative to income
df['liquidity_strength'] = df['avg_balance'] / df['avg_inflow']

# Stability Score: declared stability penalized by actual volatility
df['stability_score'] = df['income_stability_score'] / (1 + (df['inflow_volatility'] / df['avg_inflow']))
```

## Modeling Approach

### Scorecard Model
- Features normalized to 0 to 100 via Min-Max scaling
- `financial_pressure` inverted before weighting because higher pressure means higher risk
- Weighted composite: `(stability x 0.35) + (pressure_inv x 0.30) + (liquidity x 0.20) + (cashflow x 0.15)`
- Risk bands: Low (71 to 100), Medium (41 to 70), High (0 to 40)

### Logistic Regression
- `class_weight='balanced'` applied to handle the 11.5% minority default class
- `StandardScaler` applied before training to normalize feature ranges
- Model trained on 80% split (1,600 borrowers), evaluated on 20% (400 borrowers)
- Full dataset predictions generated for all 2,000 borrowers to populate the Excel dashboard

## Excel Decision System

The final output is a 6-sheet Excel workbook that operationalizes the full model pipeline:

| Sheet | Purpose |
|---|---|
| `RAW SCORECARD` | All 2,000 borrowers with raw metrics, engineered features, and scorecard outputs |
| `CREDIT RISK SCORECARD` | Normalized feature scores, weighted_score, risk_category, and ML predictions |
| `MACHINE LEARNING OUTPUT` | Full ML output table with ml_pred and ml_prob per borrower |
| `ANALYSIS` | Aggregated statistics powering the dashboard charts |
| `DASHBOARD` | Visual credit risk dashboard with KPIs, distributions, drivers, and segmentation |
| `APPLICATION VIEW` | Borrower-level approve/review/reject table for loan officers |

## Dashboard Preview

![Credit Risk Decision Dashboard](assets/dashboard_preview.png)

The dashboard displays portfolio KPIs (2,000 borrowers, 3% High Risk, 55% Medium Risk, 42% Low Risk, average default probability 0.50), risk distribution by scorecard band, scorecard vs ML alignment, default probability distribution, key risk drivers from model coefficients, and segmentation by employment type and risk category.

## How to Reproduce

**1. Set Up the Database**

Run the SQL files in order:
```bash
psql -U your_user -d your_database -f sql/01_table_creation.sql
psql -U your_user -d your_database -f sql/02_data_validation.sql
psql -U your_user -d your_database -f sql/03_views.sql
```

**2. Load Data**

Import your borrower, cashflow, and loan data into the three tables created in Step 1.

**3. Run the Python Notebook**

Open `notebooks/EXPLORATORY_DATA_ANALYSIS.ipynb` and update the connection string:
```python
engine = create_engine("postgresql://username:password@host:port/database_name")
```
Run all cells in sequence: EDA, feature engineering, scorecard, logistic regression, model comparison, output generation.

**4. Review Outputs in Excel**

Open `excel/CREDIT_SCORECARD_RISK_SCORING.xlsx` to access the full decision system, dashboard, and borrower-level approve/review/reject table.

## Dependencies

```
pandas
sqlalchemy
psycopg2
scikit-learn
matplotlib
seaborn
numpy
openpyxl
```

Install with:
```bash
pip install pandas sqlalchemy psycopg2-binary scikit-learn matplotlib seaborn numpy openpyxl
```

## Next Steps

- Retrain model on real repayment outcome data
- Automate the data pipeline from bank statement ingestion through to scoring
- Add repayment behavior features such as payment punctuality and early payment tracking
- Build segment-specific models for salary earners and business owners separately
- Integrate with open banking API for real-time scoring

## Author

**Favour Chegwe** | Credit Risk & Financial Data Analyst

[![LinkedIn](https://img.shields.io/badge/LinkedIn-favour--chegwe-blue?style=flat&logo=linkedin)](https://linkedin.com/in/favour-chegwe)
[![GitHub](https://img.shields.io/badge/GitHub-favouritefavil-black?style=flat&logo=github)](https://github.com/favouritefavil)
[![Portfolio](https://img.shields.io/badge/Portfolio-chegwefavour-green?style=flat)](https://chegwefavourlinktree.netlify.app)

*This project was built using a structured dataset simulating real-world rent financing borrower behavior. The methodology and pipeline are designed to work directly with real bank transaction data.*
