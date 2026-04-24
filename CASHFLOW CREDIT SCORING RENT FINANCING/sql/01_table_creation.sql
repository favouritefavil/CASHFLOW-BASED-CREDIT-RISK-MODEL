-- ============================================================
-- FILE: 01_table_creation.sql
-- PROJECT: Cashflow-Based Credit Scoring Model
-- DESCRIPTION: Creates the three core tables for the credit
--              risk database with proper constraints and
--              foreign key relationships.
-- ============================================================


-- ── TABLE 1: customers ──────────────────────────────────────
-- Stores static borrower profile and demographic information.
-- One row per borrower. This is the anchor table — all other
-- tables reference it via customer_id.

CREATE TABLE customers (
    customer_id             VARCHAR(20)     PRIMARY KEY,
    age                     INT,
    employment_type         VARCHAR(20),        -- salary | business | mixed
    monthly_income          DECIMAL(12, 2),
    income_stability_score  DECIMAL(5, 3),      -- 0 to 1 scale; higher = more stable
    rent_amount             DECIMAL(12, 2),
    location_type           VARCHAR(20)         -- urban | semi-urban | rural
);


-- ── TABLE 2: cashflows ──────────────────────────────────────
-- Stores monthly bank statement behavior per borrower.
-- One row per borrower per month (up to 12 rows per customer).
-- This is the behavioral financial layer — it replaces
-- traditional credit history in this scoring system.

CREATE TABLE cashflows (
    customer_id         VARCHAR(20),
    month               INT,                    -- 1 to 12
    inflow_amount       DECIMAL(12, 2),         -- total money received that month
    outflow_amount      DECIMAL(12, 2),         -- total money spent that month
    ending_balance      DECIMAL(12, 2),         -- account balance at month end
    num_transactions    INT,                    -- count of individual transactions
    inflow_source_type  VARCHAR(20),            -- salary | business_sales | mixed

    -- Enforces referential integrity: no cashflow record
    -- can exist without a valid customer in the customers table
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- ── TABLE 3: loans ──────────────────────────────────────────
-- Stores loan details and repayment outcomes.
-- One row per loan. Contains the target variable (default_flag)
-- used to train and validate the credit scoring model.

CREATE TABLE loans (
    loan_id             VARCHAR(20)     PRIMARY KEY,
    customer_id         VARCHAR(20),
    loan_amount         NUMERIC,                -- total rent amount financed
    repayment_months    INT,                    -- loan duration in months
    repayment_status    VARCHAR(20),            -- paid_on_time | late | default
    days_past_due       INT,                    -- days delayed beyond due date
    default_flag        INT,                    -- TARGET VARIABLE: 0 = repaid, 1 = defaulted
    risk_score          NUMERIC,                -- pre-computed reference score

    -- Enforces referential integrity: every loan must belong
    -- to a valid customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
