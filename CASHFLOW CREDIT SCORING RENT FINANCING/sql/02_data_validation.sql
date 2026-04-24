-- ============================================================
-- FILE: 02_data_validation.sql
-- PROJECT: Cashflow-Based Credit Scoring Model
-- DESCRIPTION: 10 validation checks run before any analysis
--              or modeling. Catches nulls, duplicates, orphaned
--              records, and logical inconsistencies that would
--              corrupt model inputs if left unaddressed.
--
-- HOW TO USE: Run each block sequentially. Any query that
--             returns rows indicates a data quality issue
--             that must be resolved before proceeding.
-- ============================================================


-- ── CHECK 1: Null values in customers ───────────────────────
-- Required fields must be populated for every borrower.
-- A null income or employment type makes scoring impossible.

SELECT *
FROM customers
WHERE customer_id        IS NULL
   OR age                IS NULL
   OR employment_type    IS NULL
   OR monthly_income     IS NULL
   OR rent_amount        IS NULL;


-- ── CHECK 2: Null values in cashflows ───────────────────────
-- Null cashflow values propagate through every feature
-- calculation and corrupt the engineered features.

SELECT *
FROM cashflows
WHERE customer_id      IS NULL
   OR inflow_amount    IS NULL
   OR outflow_amount   IS NULL
   OR ending_balance   IS NULL;


-- ── CHECK 3: Null values in loans ───────────────────────────
-- A null default_flag means the model has no outcome to learn
-- from. These rows must be excluded from model training.

SELECT *
FROM loans
WHERE loan_id       IS NULL
   OR customer_id   IS NULL
   OR loan_amount   IS NULL
   OR default_flag  IS NULL;


-- ── CHECK 4: Duplicate customer records ─────────────────────
-- Each borrower should appear exactly once in the customers
-- table. Duplicates inflate sample sizes and introduce bias.

SELECT customer_id, COUNT(*) AS record_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ── CHECK 5: Duplicate loan records ─────────────────────────
-- Duplicate loans double-count defaults and distort the
-- portfolio default rate calculation.

SELECT loan_id, COUNT(*) AS record_count
FROM loans
GROUP BY loan_id
HAVING COUNT(*) > 1;


-- ── CHECK 6: Orphaned cashflow records ──────────────────────
-- Cashflow rows with no matching customer cannot be linked
-- to borrower profile data. They produce null values in joins.

SELECT cf.*
FROM cashflows cf
LEFT JOIN customers c
    ON cf.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ── CHECK 7: Orphaned loan records ──────────────────────────
-- Loan rows with no matching customer cannot be used in
-- analysis or model training.

SELECT l.*
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ── CHECK 8: Negative cashflow values ───────────────────────
-- Negative inflows or outflows indicate data entry errors
-- or accounting reversals requiring investigation.

SELECT *
FROM cashflows
WHERE inflow_amount  < 0
   OR outflow_amount < 0;


-- ── CHECK 9: Extreme expense ratio ──────────────────────────
-- An expense ratio above 2.0 means a borrower spent more
-- than twice their inflow — either a data error or an extreme
-- outlier that needs review before modeling.
-- NULLIF prevents division-by-zero on months with zero inflow.

SELECT
    customer_id,
    month,
    inflow_amount,
    outflow_amount,
    ROUND((outflow_amount / NULLIF(inflow_amount, 0))::NUMERIC, 4) AS expense_ratio
FROM cashflows
WHERE (outflow_amount / NULLIF(inflow_amount, 0)) > 2;


-- ── CHECK 10: Default flag integrity ────────────────────────
-- The target variable must be strictly binary (0 or 1).
-- Any other value breaks the classification model.

SELECT *
FROM loans
WHERE default_flag NOT IN (0, 1);


-- ── BONUS: Portfolio default rate summary ───────────────────
-- Validates that the overall default rate falls within the
-- expected range (10–25%). An unexpected rate signals a
-- data sampling or labeling problem.

SELECT
    COUNT(*)                                    AS total_loans,
    SUM(default_flag)                           AS total_defaults,
    ROUND(AVG(default_flag)::NUMERIC * 100, 2) AS default_rate_pct
FROM loans;
