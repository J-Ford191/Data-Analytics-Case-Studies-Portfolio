-- ============================================
-- controls_log.sql
-- Lightweight data-quality checks for events_all.
-- Run after setup_events_all.sql
-- ============================================

-- Row count & time bounds
SELECT COUNT(*) AS rows_total,
       MIN(txn_aest_dt) AS min_aest_dt,
       MAX(txn_aest_dt) AS max_aest_dt,
       COUNT(DISTINCT SiteId) AS sites,
       COUNT(DISTINCT Site_Suburb) AS suburbs,
       COUNT(DISTINCT Fuel_Type) AS fuel_types
FROM events_all;

-- Nulls quick scan (selected fields)
SELECT
  SUM(SiteId IS NULL)           AS n_null_siteid,
  SUM(Site_Name IS NULL)        AS n_null_site_name,
  SUM(Site_Brand IS NULL)       AS n_null_site_brand,
  SUM(Site_Suburb IS NULL)      AS n_null_suburb,
  SUM(Fuel_Type IS NULL)        AS n_null_fuel,
  SUM(Price IS NULL)            AS n_null_price,
  SUM(TransactionDateutc IS NULL) AS n_null_txn_utc
FROM events_all;

-- Special values & ranges
SELECT
  SUM(Price = 9999) AS n_unavailable,
  ROUND(MIN(price_cpl),1) AS min_cpl_raw,
  ROUND(MAX(price_cpl),1) AS max_cpl_raw,
  SUM(is_outlier) AS n_outliers,
  SUM(dup_price_conflict) AS n_dup_price_conflict
FROM events_all
WHERE is_qld=1;

-- Price bands by fuel (exclude unavailable & outliers)
SELECT Fuel_Type,
       ROUND(AVG(price_cpl),1) AS avg_cpl,
       ROUND(MIN(price_cpl),1) AS min_cpl,
       ROUND(MAX(price_cpl),1) AS max_cpl,
       COUNT(*) AS rows
FROM events_all
WHERE is_qld=1 AND is_unavailable=0 AND is_outlier=0
GROUP BY Fuel_Type
ORDER BY Fuel_Type;

-- Integrity: ensure all ticks match at least one interval
SELECT COUNT(*) AS unmatched_ticks
FROM t_tick_min m
LEFT JOIN ev_intervals i
  ON m.Site_Suburb=i.Site_Suburb AND m.Fuel_Type=i.Fuel_Type
 AND m.tick_ts >= i.start_dt AND m.tick_ts < i.end_dt
WHERE i.SiteId IS NULL;
