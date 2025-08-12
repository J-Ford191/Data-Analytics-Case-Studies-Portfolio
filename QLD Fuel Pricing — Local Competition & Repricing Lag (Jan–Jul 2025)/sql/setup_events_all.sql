-- ============================================
-- setup_events_all.sql
-- Build a materialized clean table (events_all) from Jan–Jul 2025 staging tables.
-- Compatible with SQLite.
-- ============================================

PRAGMA journal_mode=WAL;
PRAGMA temp_store=MEMORY;

DROP TABLE IF EXISTS events_all;
CREATE TABLE events_all AS
WITH unioned AS (
  SELECT SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
         Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc
  FROM stg_qld_fuel_2025_01
  UNION ALL SELECT SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
         Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc
  FROM stg_qld_fuel_2025_02
  UNION ALL SELECT SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
         Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc
  FROM stg_qld_fuel_2025_03
  UNION ALL SELECT SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
         Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc
  FROM stg_qld_fuel_2025_04
  UNION ALL SELECT SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
         Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc
  FROM stg_qld_fuel_2025_05
  UNION ALL SELECT SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
         Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc
  FROM stg_qld_fuel_2025_06
  UNION ALL SELECT SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
         Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc
  FROM stg_qld_fuel_2025_07
),
dedup AS (
  SELECT
    u.*,
    MIN(Price) OVER (PARTITION BY SiteId, Fuel_Type, TransactionDateutc) AS grp_min_price,
    MAX(Price) OVER (PARTITION BY SiteId, Fuel_Type, TransactionDateutc) AS grp_max_price,
    ROW_NUMBER() OVER (
      PARTITION BY SiteId, Fuel_Type, TransactionDateutc
      ORDER BY Price DESC
    ) AS rn
  FROM unioned u
),
base AS (
  SELECT *
  FROM dedup
  WHERE rn = 1
),
parsed AS (
  SELECT
    SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
    Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc,
    grp_min_price, grp_max_price,

    (substr(TransactionDateutc,7,4) || '-' || substr(TransactionDateutc,4,2) || '-' ||
     substr(TransactionDateutc,1,2) || ' ' || substr(TransactionDateutc,12,5) || ':00') AS iso_utc,
    datetime(
      substr(TransactionDateutc,7,4) || '-' || substr(TransactionDateutc,4,2) || '-' ||
      substr(TransactionDateutc,1,2) || ' ' || substr(TransactionDateutc,12,5) || ':00'
    ) AS txn_utc_dt,
    datetime(
      datetime(
        substr(TransactionDateutc,7,4) || '-' || substr(TransactionDateutc,4,2) || '-' ||
        substr(TransactionDateutc,1,2) || ' ' || substr(TransactionDateutc,12,5) || ':00'
      ), '+10 hours'
    ) AS txn_aest_dt
  FROM base
),
enriched AS (
  SELECT
    *,
    CASE WHEN Price = 9999 THEN 1 ELSE 0 END AS is_unavailable,
    CASE WHEN Price <> 9999 THEN Price/10.0 END AS price_cpl,
    CASE WHEN Site_State = 'QLD' THEN 1 ELSE 0 END AS is_qld
  FROM parsed
),
flagged AS (
  SELECT
    e.*,
    CASE WHEN grp_min_price <> grp_max_price THEN 1 ELSE 0 END AS dup_price_conflict,
    CASE
      WHEN price_cpl IS NULL THEN 0
      WHEN Fuel_Type LIKE '%Unleaded%'            AND (price_cpl < 120 OR price_cpl > 260) THEN 1
      WHEN Fuel_Type = 'e10'                      AND (price_cpl < 110 OR price_cpl > 240) THEN 1
      WHEN Fuel_Type = 'Diesel'                   AND (price_cpl < 120 OR price_cpl > 260) THEN 1
      WHEN Fuel_Type = 'Premium Diesel'           AND (price_cpl < 140 OR price_cpl > 250) THEN 1
      WHEN Fuel_Type LIKE 'PULP 95%'              AND (price_cpl < 140 OR price_cpl > 260) THEN 1
      WHEN Fuel_Type LIKE 'PULP 98%'              AND (price_cpl < 150 OR price_cpl > 260) THEN 1
      WHEN Fuel_Type = 'LPG'                      AND (price_cpl <  90 OR price_cpl > 170) THEN 1
      WHEN Fuel_Type = 'OPAL'                     AND (price_cpl < 180 OR price_cpl > 240) THEN 1
      WHEN Fuel_Type = 'e85'                      AND (price_cpl < 200 OR price_cpl > 240) THEN 1
      ELSE 0
    END AS is_outlier
  FROM enriched e
)
SELECT
  CAST(NULL AS INTEGER) AS id,
  SiteId, Site_Name, Site_Brand, Sites_Address_Line_1, Site_Suburb, Site_State,
  Site_Post_Code, Site_Latitude, Site_Longitude, Fuel_Type, Price, TransactionDateutc,
  iso_utc, txn_utc_dt, txn_aest_dt,
  is_unavailable, price_cpl, is_qld, dup_price_conflict, is_outlier
FROM flagged
;

-- add surrogate key
UPDATE events_all SET id = rowid;

-- indexes
CREATE INDEX IF NOT EXISTS idx_ev_suburb_fuel_dt ON events_all (Site_Suburb, Fuel_Type, txn_aest_dt);
CREATE INDEX IF NOT EXISTS idx_ev_site_fuel_dt   ON events_all (SiteId, Fuel_Type, txn_aest_dt);
CREATE INDEX IF NOT EXISTS idx_ev_flags          ON events_all (is_qld, is_unavailable, is_outlier);
CREATE INDEX IF NOT EXISTS idx_ev_state          ON events_all (Site_State);

-- helper intervals for metrics
DROP TABLE IF EXISTS ev_intervals;
CREATE TABLE ev_intervals AS
WITH base AS (
  SELECT
    SiteId, Site_Name, Site_Brand, Site_Suburb, Fuel_Type, price_cpl, txn_aest_dt,
    LEAD(txn_aest_dt) OVER (PARTITION BY SiteId, Fuel_Type ORDER BY txn_aest_dt) AS next_dt
  FROM events_all
  WHERE is_qld=1 AND is_unavailable=0 AND is_outlier=0
)
SELECT
  SiteId, Site_Name, Site_Brand, Site_Suburb, Fuel_Type, price_cpl,
  txn_aest_dt AS start_dt,
  COALESCE(next_dt, datetime((SELECT MAX(txn_aest_dt) FROM events_all), '+1 hour')) AS end_dt
FROM base
;

CREATE INDEX IF NOT EXISTS idx_iv_sub_fuel ON ev_intervals (Site_Suburb, Fuel_Type, start_dt, end_dt);

-- global ticks where any site changed per (suburb,fuel)
DROP TABLE IF EXISTS t_ticks;
CREATE TABLE t_ticks AS
WITH ticks AS (
  SELECT DISTINCT Site_Suburb, Fuel_Type, txn_aest_dt AS tick_ts
  FROM events_all
  WHERE is_qld=1 AND is_unavailable=0 AND is_outlier=0
),
nn AS (
  SELECT Site_Suburb, Fuel_Type, tick_ts,
         LEAD(tick_ts) OVER (PARTITION BY Site_Suburb, Fuel_Type ORDER BY tick_ts) AS next_tick_ts
  FROM ticks
)
SELECT Site_Suburb, Fuel_Type, tick_ts,
       COALESCE(next_tick_ts, datetime(tick_ts, '+1 hour')) AS next_tick_ts
FROM nn
;

CREATE INDEX IF NOT EXISTS idx_ticks_sub_fuel ON t_ticks (Site_Suburb, Fuel_Type, tick_ts);

-- precompute local minima per tick interval
DROP TABLE IF EXISTS t_tick_min;
CREATE TABLE t_tick_min AS
SELECT
  t.Site_Suburb, t.Fuel_Type, t.tick_ts, t.next_tick_ts,
  MIN(i.price_cpl) AS min_price
FROM t_ticks t
JOIN ev_intervals i
  ON i.Site_Suburb=t.Site_Suburb AND i.Fuel_Type=t.Fuel_Type
 AND t.tick_ts >= i.start_dt AND t.tick_ts < i.end_dt
GROUP BY t.Site_Suburb, t.Fuel_Type, t.tick_ts, t.next_tick_ts
;

CREATE INDEX IF NOT EXISTS idx_tick_min_sub_fuel ON t_tick_min (Site_Suburb, Fuel_Type, tick_ts);
