-- ============================================================
-- FILE: 03_views.sql
-- PROJECT: Cashflow-Based Credit Scoring Model
-- DESCRIPTION: Three SQL views that aggregate, join, and
--              prepare data for Python feature engineering
--              and modeling. Views compute dynamically —
--              raw data is never modified.
--
-- VIEW ORDER:
--   1. customer_cashflow_summary  → aggregated cashflow metrics
--   2. rent_burden                → rent-to-income ratio
--   3. model_dataset              → unified analysis-ready view
--                                   (loaded directly into Python)
-- ============================================================


-- ── VIEW 1: customer_cashflow_summary ───────────────────────
-- Aggregates 6–12 months of cashflow data per borrower into
-- a single summary row. Produces the six base metrics that
-- feed into Python feature engineering.
--
-- Key design decisions:
--   · NULLIF(inflow_amount, 0) prevents division-by-zero
--     in the expense ratio calculation
--   · STDDEV(inflow_amount) measures income volatility —
--     the foundation of the stability_score feature

CREATE VIEW customer_cashflow_summary AS
SELECT
    customer_id,
    AVG(inflow_amount)                                      AS avg_inflow,
    AVG(outflow_amount)                                     AS avg_outflow,
    AVG(inflow_amount - outflow_amount)                     AS avg_net_cashflow,
    AVG(outflow_amount / NULLIF(inflow_amount, 0))          AS avg_expense_ratio,
    AVG(ending_balance)                                     AS avg_balance,
    STDDEV(inflow_amount)                                   AS inflow_volatility
FROM cashflows
GROUP BY customer_id;


-- ── VIEW 2: rent_burden ─────────────────────────────────────
-- Calculates the rent-to-income ratio for each borrower:
-- what fraction of declared monthly income is committed to rent.
--
-- This is a key risk indicator specific to rent financing —
-- a borrower committing more than 30–35% of income to rent
-- has significantly less room to absorb repayment obligations.

CREATE VIEW rent_burden AS
SELECT
    c.customer_id,
    c.monthly_income,
    c.rent_amount,
    (c.rent_amount / NULLIF(c.monthly_income, 0))           AS rent_to_income_ratio
FROM customers c;


-- ── VIEW 3: model_dataset ───────────────────────────────────
-- Master view: joins all three tables and both sub-views into
-- one wide, analysis-ready dataset. This is the single query
-- loaded into Python via SQLAlchemy for all downstream work.
--
-- Result: one row per borrower, 18 columns covering borrower
-- profile, cashflow behavior, rent burden, loan details, and
-- the target variable (default_flag).
--
-- Load in Python with:
--   query = "SELECT * FROM model_dataset;"
--   df = pd.read_sql(query, engine)

CREATE VIEW model_dataset AS
SELECT
    -- Borrower profile
    c.customer_id,
    c.age,
    c.employment_type,
    c.monthly_income,
    c.income_stability_score,
    c.rent_amount,
    c.location_type,

    -- Aggregated cashflow behavior (from customer_cashflow_summary)
    cf.avg_inflow,
    cf.avg_outflow,
    cf.avg_net_cashflow,
    cf.avg_expense_ratio,
    cf.avg_balance,
    cf.inflow_volatility,

    -- Rent burden (from rent_burden)
    rb.rent_to_income_ratio,

    -- Loan details and target variable
    l.loan_amount,
    l.repayment_status,
    l.days_past_due,
    l.default_flag                  -- TARGET: 0 = repaid, 1 = defaulted

FROM customers c
JOIN customer_cashflow_summary cf
    ON c.customer_id = cf.customer_id
JOIN rent_burden rb
    ON c.customer_id = rb.customer_id
JOIN loans l
    ON c.customer_id = l.customer_id;


-- ── VERIFY VIEWS ────────────────────────────────────────────
-- Run these after creating the views to confirm they load
-- correctly and return the expected number of rows.

SELECT * FROM model_dataset            LIMIT 5;
SELECT * FROM customer_cashflow_summary LIMIT 5;
SELECT * FROM rent_burden              LIMIT 5;
