-- analysis_views.sql
-- Competitive metrics, price index, lowest-price share, and promo undercutting

-- 4) Item-level competition metrics
DROP VIEW IF EXISTS vw_item_competition;
CREATE VIEW vw_item_competition AS
WITH base AS (
  SELECT
    category_1, category_2, category_3,
    product_code, brand, product_name,
    retailer, price, promo_flag
  FROM vw_pricewatch_valid v
  JOIN vw_overlap_items o USING (product_code)
),
stats AS (
  SELECT product_code, MIN(price) AS min_price, AVG(price) AS avg_price
  FROM base
  GROUP BY product_code
),
lowest_counts AS (
  SELECT b.product_code, COUNT(*) AS n_lowest
  FROM base b
  JOIN stats s USING (product_code)
  WHERE b.price = s.min_price
  GROUP BY b.product_code
)
SELECT
  b.*,
  s.min_price,
  s.avg_price,
  ROUND(100.0 * b.price / s.avg_price, 2)        AS price_index,
  CASE WHEN b.price = s.min_price THEN 1 ELSE 0 END AS is_lowest,
  lc.n_lowest                                     AS n_lowest_tied
FROM base b
JOIN stats s       USING (product_code)
JOIN lowest_counts lc USING (product_code);

-- 5) Category-level price index
DROP VIEW IF EXISTS vw_cat_price_index;
CREATE VIEW vw_cat_price_index AS
SELECT
  category_1,
  retailer,
  COUNT(*)                   AS n_items,
  ROUND(AVG(price_index), 2) AS avg_price_index
FROM vw_item_competition
GROUP BY category_1, retailer;

-- 6) Lowest-price share by category (tie-weighted)
DROP VIEW IF EXISTS vw_cat_lowest_share;
CREATE VIEW vw_cat_lowest_share AS
SELECT
  category_1,
  retailer,
  ROUND(SUM(CASE WHEN is_lowest=1 THEN 1.0 / n_lowest_tied ELSE 0 END), 2) AS lowest_wins,
  COUNT(*) AS n_items,
  ROUND(100.0 * SUM(CASE WHEN is_lowest=1 THEN 1.0 / n_lowest_tied ELSE 0 END) / COUNT(*), 2) AS lowest_share_pct
FROM vw_item_competition
GROUP BY category_1, retailer;

-- 7) Promo undercutting vs non-promo (per category & retailer)
DROP VIEW IF EXISTS vw_cat_promo_undercut;
CREATE VIEW vw_cat_promo_undercut AS
WITH grouped AS (
  SELECT category_1, retailer, promo_flag,
         SUM(CASE WHEN is_lowest=1 THEN 1.0 / n_lowest_tied ELSE 0 END) AS lowest_wins,
         COUNT(*) AS n_items
  FROM vw_item_competition
  GROUP BY category_1, retailer, promo_flag
)
SELECT
  category_1,
  retailer,
  ROUND(100.0 * SUM(CASE WHEN promo_flag=1 THEN lowest_wins ELSE 0 END) /
               NULLIF(SUM(CASE WHEN promo_flag=1 THEN n_items ELSE 0 END), 0), 2) AS promo_undercut_pct,
  SUM(CASE WHEN promo_flag=1 THEN n_items ELSE 0 END) AS promo_items,
  ROUND(100.0 * SUM(CASE WHEN promo_flag=0 THEN lowest_wins ELSE 0 END) /
               NULLIF(SUM(CASE WHEN promo_flag=0 THEN n_items ELSE 0 END), 0), 2) AS nonpromo_undercut_pct,
  SUM(CASE WHEN promo_flag=0 THEN n_items ELSE 0 END) AS nonpromo_items
FROM grouped
GROUP BY category_1, retailer;

-- Suggested result queries:
-- SELECT * FROM vw_cat_price_index ORDER BY category_1, avg_price_index;
-- SELECT * FROM vw_cat_lowest_share ORDER BY category_1, lowest_share_pct DESC;
-- SELECT * FROM vw_cat_promo_undercut ORDER BY category_1, retailer;