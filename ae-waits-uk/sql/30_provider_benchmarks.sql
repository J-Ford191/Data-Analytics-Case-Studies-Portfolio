-- 30_provider_benchmarks.sql
CREATE OR REPLACE VIEW v_benchmarks AS
SELECT
  provider_code,
  month_date,
  pct_within_4h,
  rate_12h_from_arrival,
  admit_conversion,
  over4h_dta_rate,
  pct_within_4h - LAG(pct_within_4h) OVER (PARTITION BY provider_code ORDER BY month_date) AS mom_delta_4h,
  rate_12h_from_arrival - LAG(rate_12h_from_arrival) OVER (PARTITION BY provider_code ORDER BY month_date) AS mom_delta_12h
FROM v_provider_monthly;
