-- 20_kpi_views.sql
CREATE OR REPLACE VIEW v_provider_monthly AS
SELECT
  a.provider_code,
  a.provider_name,
  a.month_date,
  total_attendances,
  within_4h_count,
  emergency_admissions,
  over4h_after_dta,
  e.type12_attendances,
  e.arrivals_12h_or_more,
  ROUND(within_4h_count * 1.0 / NULLIF(total_attendances,0), 4) AS pct_within_4h,
  ROUND(arrivals_12h_or_more * 1.0 / NULLIF(e.type12_attendances,0), 4) AS rate_12h_from_arrival,
  ROUND(emergency_admissions * 1.0 / NULLIF(e.type12_attendances,0), 4) AS admit_conversion,
  ROUND(over4h_after_dta * 1.0 / NULLIF(emergency_admissions,0), 4) AS over4h_dta_rate
FROM stg_monthly_ae a
LEFT JOIN (
  SELECT provider_code, month_date,
         SUM(type12_attendances) AS type12_attendances,
         SUM(arrivals_12h_or_more) AS arrivals_12h_or_more
  FROM stg_ecds_monthly
  GROUP BY 1,2
) e ON e.provider_code = a.provider_code AND e.month_date = a.month_date;
