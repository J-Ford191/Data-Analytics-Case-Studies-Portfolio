-- 00_schema.sql
CREATE TABLE stg_monthly_ae (
  provider_code TEXT,
  provider_name TEXT,
  month_date DATE,
  total_attendances INT,
  within_4h_count INT,
  emergency_admissions INT,
  over4h_after_dta INT
);

CREATE TABLE stg_ecds_monthly (
  provider_code TEXT,
  provider_name TEXT,
  month_date DATE,
  type12_attendances INT,
  arrivals_12h_or_more INT,
  age_band TEXT,     -- optional breakdowns
  cfs_band TEXT      -- frailty CFS 1–9 (from Dec 12, 2024)
);
