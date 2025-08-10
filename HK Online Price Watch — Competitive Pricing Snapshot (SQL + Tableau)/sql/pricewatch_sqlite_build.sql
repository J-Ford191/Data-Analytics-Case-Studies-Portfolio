-- 0) Confirm table & columns
PRAGMA table_info('pricewatch_raw');

-- 1) Row count
SELECT COUNT(*) AS row_count FROM pricewatch_raw;

-- 2) First 5 rows (sanity check)
SELECT * FROM pricewatch_raw LIMIT 5;

-- 3) Retailer coverage
SELECT "Supermarket Code" AS supermarket_code, COUNT(*) AS n
FROM pricewatch_raw
GROUP BY "Supermarket Code"
ORDER BY n DESC;

-- 4) Price ranges (robust cast in case price imported as text)
SELECT
  MIN(CAST(NULLIF(TRIM("Price"), '') AS REAL)) AS min_price,
  AVG(CAST(NULLIF(TRIM("Price"), '') AS REAL)) AS avg_price,
  MAX(CAST(NULLIF(TRIM("Price"), '') AS REAL)) AS max_price
FROM pricewatch_raw;

-- 5) Category breadth (top level)
SELECT "Category 1" AS cat1, COUNT(*) AS n
FROM pricewatch_raw
GROUP BY "Category 1"
ORDER BY n DESC
LIMIT 15;

-- 6) Offers coverage (any promo text present?)
SELECT
  CASE WHEN "Offers" IS NULL OR TRIM("Offers") = '' THEN 0 ELSE 1 END AS has_offer,
  COUNT(*) AS n
FROM pricewatch_raw
GROUP BY has_offer;

-- Retailer coverage
SELECT Supermarket_Code AS supermarket_code, COUNT(*) AS n
FROM pricewatch_raw
GROUP BY Supermarket_Code
ORDER BY n DESC;

-- Category breadth
SELECT Category_1 AS cat1, COUNT(*) AS n
FROM pricewatch_raw
GROUP BY Category_1
ORDER BY n DESC
LIMIT 15;

-- Cleaned view: trim text, standardize retailer code, cast price, add promo_flag
DROP VIEW IF EXISTS vw_pricewatch_clean;
CREATE VIEW vw_pricewatch_clean AS
SELECT
  TRIM(Category_1)              AS category_1,
  TRIM(Category_2)              AS category_2,
  TRIM(Category_3)              AS category_3,
  TRIM(Product_Code)            AS product_code,
  TRIM(Brand)                   AS brand,
  TRIM(Product_Name)            AS product_name,
  UPPER(TRIM(Supermarket_Code)) AS retailer,
  CAST(NULLIF(TRIM(Price), '') AS REAL) AS price,
  CASE WHEN Offers IS NOT NULL AND TRIM(Offers) <> '' THEN 1 ELSE 0 END AS promo_flag,
  TRIM(Offers)                  AS offers_text
FROM pricewatch_raw;

-- Valid view: keep only positive, non-null prices (zeros excluded)
DROP VIEW IF EXISTS vw_pricewatch_valid;
CREATE VIEW vw_pricewatch_valid AS
SELECT *
FROM vw_pricewatch_clean
WHERE price IS NOT NULL AND price > 0;

-- Counts
SELECT
  (SELECT COUNT(*) FROM pricewatch_raw)         AS raw_rows,
  (SELECT COUNT(*) FROM vw_pricewatch_clean)    AS clean_rows,
  (SELECT COUNT(*) FROM vw_pricewatch_valid)    AS valid_rows;

-- Price ranges on valid rows
SELECT MIN(price) AS min_price, AVG(price) AS avg_price, MAX(price) AS max_price
FROM vw_pricewatch_valid;

-- Promo coverage
SELECT promo_flag, COUNT(*) AS n
FROM vw_pricewatch_clean
GROUP BY promo_flag;

-- Retailers (post-clean)
SELECT retailer, COUNT(*) AS n
FROM vw_pricewatch_valid
GROUP BY retailer
ORDER BY n DESC;

-- Top categories (post-clean)
SELECT category_1, COUNT(*) AS n
FROM vw_pricewatch_valid
GROUP BY category_1
ORDER BY n DESC
LIMIT 15;

-- A) Duplicates: same product & retailer appearing more than once?
SELECT product_code, retailer, COUNT(*) AS c
FROM vw_pricewatch_valid
GROUP BY product_code, retailer
HAVING c > 1
ORDER BY c DESC
LIMIT 20;

-- B) Overlap: how many retailers carry the SAME item?
WITH prod_retailers AS (
  SELECT product_code, COUNT(DISTINCT retailer) AS retailers
  FROM vw_pricewatch_valid
  GROUP BY product_code
)
SELECT retailers, COUNT(*) AS n_products
FROM prod_retailers
GROUP BY retailers
ORDER BY retailers DESC;

-- C) Spot-check top priced items (to decide if we cap outliers later)
SELECT category_1, brand, product_name, retailer, price
FROM vw_pricewatch_valid
ORDER BY price DESC
LIMIT 10;

-- 5.1 Keep only items sold by 2+ retailers (apples-to-apples)
DROP VIEW IF EXISTS vw_overlap_items;
CREATE VIEW vw_overlap_items AS
SELECT product_code
FROM vw_pricewatch_valid
GROUP BY product_code
HAVING COUNT(DISTINCT retailer) >= 2;

-- 5.2 Item-level competition metrics (min price, avg price, price index, tie-aware lowest flag)
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

-- 5.3 Category-level Price Index (avg index across overlapping items)
DROP VIEW IF EXISTS vw_cat_price_index;
CREATE VIEW vw_cat_price_index AS
SELECT
  category_1,
  retailer,
  COUNT(*)                         AS n_items,
  ROUND(AVG(price_index), 2)       AS avg_price_index
FROM vw_item_competition
GROUP BY category_1, retailer;

-- 5.4 Lowest-price share by category (tie-weighted)
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

-- 5.5 Promo undercutting vs non-promo (same category & retailer)
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

-- Top categories by item count (focus list for charts)
SELECT category_1, SUM(n_items) AS items
FROM vw_cat_price_index
GROUP BY category_1
ORDER BY items DESC
LIMIT 10;

-- Category leaderboard (lowest-price share + price index)
SELECT
  c.category_1,
  c.retailer,
  c.lowest_share_pct,
  c.n_items,
  p.avg_price_index
FROM vw_cat_lowest_share c
JOIN vw_cat_price_index p
  ON p.category_1 = c.category_1 AND p.retailer = c.retailer
ORDER BY c.category_1, c.lowest_share_pct DESC;

-- Promo undercutting vs non-promo (per category & retailer)
SELECT *
FROM vw_cat_promo_undercut
ORDER BY category_1, retailer;

-- Category leaderboard: lowest-price share + avg price index
SELECT
  c.category_1,
  c.retailer,
  c.lowest_share_pct,
  c.n_items,
  p.avg_price_index
FROM vw_cat_lowest_share c
JOIN vw_cat_price_index p
  ON p.category_1 = c.category_1 AND p.retailer = c.retailer
ORDER BY c.category_1, c.lowest_share_pct DESC;

-- Promo undercutting vs non-promo
SELECT *
FROM vw_cat_promo_undercut
ORDER BY category_1, retailer;

-- Category leaderboard: lowest-price share + avg price index
SELECT
  c.category_1,
  c.retailer,
  c.lowest_share_pct,
  c.n_items,
  p.avg_price_index
FROM vw_cat_lowest_share c
JOIN vw_cat_price_index p
  ON p.category_1 = c.category_1 AND p.retailer = c.retailer
WHERE c.category_1 IN (
  'Personal care',
  'Noodles / Cooking needs / Processed food (cold)',
  'Candies / Biscuits / Snacks',
  'Drinks'
)
ORDER BY c.category_1, c.lowest_share_pct DESC;

-- Promo undercutting vs non-promo
SELECT *
FROM vw_cat_promo_undercut
WHERE category_1 IN (
  'Personal care',
  'Noodles / Cooking needs / Processed food (cold)',
  'Candies / Biscuits / Snacks',
  'Drinks'
)
ORDER BY category_1, retailer;

