-- ============================================
-- metrics_tables.sql
-- Create repricing lag and lowest-price share tables from events_all.
-- Requires helper tables built by setup_events_all.sql (ev_intervals, t_ticks, t_tick_min).
-- ============================================

-- Repricing Lag (site-level)
DROP TABLE IF EXISTS tbl_repricing_lag_site;
CREATE TABLE tbl_repricing_lag_site AS
WITH e AS (
  SELECT SiteId, Site_Name, Site_Brand, Site_Suburb, Fuel_Type, txn_aest_dt
  FROM events_all
  WHERE is_qld=1 AND is_unavailable=0 AND is_outlier=0
),
lags AS (
  SELECT
    e.SiteId, e.Site_Name, e.Site_Brand, e.Site_Suburb, e.Fuel_Type, e.txn_aest_dt,
    (SELECT MAX(c.txn_aest_dt)
     FROM events_all c
     WHERE c.Site_Suburb=e.Site_Suburb
       AND c.Fuel_Type=e.Fuel_Type
       AND c.SiteId <> e.SiteId
       AND c.is_qld=1 AND c.is_unavailable=0 AND c.is_outlier=0
       AND c.txn_aest_dt < e.txn_aest_dt) AS last_comp_ts
  FROM e
),
clean AS (
  SELECT *,
         ROUND((julianday(txn_aest_dt) - julianday(last_comp_ts)) * 1440.0, 1) AS lag_minutes
  FROM lags
  WHERE last_comp_ts IS NOT NULL
    AND (julianday(txn_aest_dt) - julianday(last_comp_ts)) >= 0
),
grp AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY SiteId, Site_Suburb, Fuel_Type ORDER BY lag_minutes) AS rn,
         COUNT(*)    OVER (PARTITION BY SiteId, Site_Suburb, Fuel_Type) AS cnt
  FROM clean
),
mid AS (
  SELECT SiteId, Site_Suburb, Fuel_Type, lag_minutes
  FROM grp
  WHERE rn IN ( (cnt + 1)/2, (cnt + 2)/2 )
),
stats AS (
  SELECT SiteId, Site_Name, Site_Brand, Site_Suburb, Fuel_Type,
         COUNT(*) AS change_events,
         ROUND(AVG(lag_minutes),1) AS avg_lag_minutes
  FROM clean
  GROUP BY SiteId, Site_Name, Site_Brand, Site_Suburb, Fuel_Type
),
med AS (
  SELECT SiteId, Site_Suburb, Fuel_Type,
         ROUND(AVG(lag_minutes),1) AS median_lag_minutes
  FROM mid
  GROUP BY SiteId, Site_Suburb, Fuel_Type
)
SELECT s.SiteId, s.Site_Name, s.Site_Brand, s.Site_Suburb, s.Fuel_Type,
       s.change_events, s.avg_lag_minutes, m.median_lag_minutes
FROM stats s
LEFT JOIN med m
  ON m.SiteId=s.SiteId AND m.Site_Suburb=s.Site_Suburb AND m.Fuel_Type=s.Fuel_Type
;

-- Lowest-Price Share (duration-weighted)
DROP TABLE IF EXISTS tbl_lowest_price_share;
CREATE TABLE tbl_lowest_price_share AS
WITH winners AS (
  SELECT
    i.SiteId, i.Site_Name, i.Site_Brand, i.Site_Suburb, i.Fuel_Type,
    SUM( (julianday(m.next_tick_ts) - julianday(m.tick_ts)) * 1440.0 ) AS minutes_lowest
  FROM ev_intervals i
  JOIN t_tick_min m
    ON m.Site_Suburb=i.Site_Suburb AND m.Fuel_Type=i.Fuel_Type
   AND m.tick_ts >= i.start_dt AND m.tick_ts < i.end_dt
   AND ABS(i.price_cpl - m.min_price) < 0.0001
  GROUP BY i.SiteId, i.Site_Name, i.Site_Brand, i.Site_Suburb, i.Fuel_Type
),
denom AS (
  SELECT Site_Suburb, Fuel_Type,
         SUM( (julianday(next_tick_ts) - julianday(tick_ts)) * 1440.0 ) AS minutes_total
  FROM t_tick_min
  GROUP BY Site_Suburb, Fuel_Type
),
avgp AS (
  SELECT SiteId, Site_Suburb, Fuel_Type, ROUND(AVG(price_cpl),1) AS avg_cpl
  FROM ev_intervals
  GROUP BY SiteId, Site_Suburb, Fuel_Type
)
SELECT
  w.SiteId, w.Site_Name, w.Site_Brand, w.Site_Suburb, w.Fuel_Type,
  ROUND(w.minutes_lowest,1) AS minutes_lowest,
  d.minutes_total,
  ROUND(100.0 * w.minutes_lowest / d.minutes_total, 2) AS lowest_price_share_pct,
  a.avg_cpl
FROM winners w
JOIN denom d USING (Site_Suburb, Fuel_Type)
LEFT JOIN avgp a USING (SiteId, Site_Suburb, Fuel_Type)
;
