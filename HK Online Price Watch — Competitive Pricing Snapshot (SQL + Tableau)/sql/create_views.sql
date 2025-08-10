-- create_views.sql
-- Base cleaning & foundational views for HK Online Price Watch (SQLite)
-- Assumes a table named pricewatch_raw with columns:
-- Category_1, Category_2, Category_3, Product_Code, Brand, Product_Name, Supermarket_Code, Price, Offers

-- 1) Clean view: standardize text, cast price, add promo flag
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

-- 2) Valid view: drop null/zero prices
DROP VIEW IF EXISTS vw_pricewatch_valid;
CREATE VIEW vw_pricewatch_valid AS
SELECT *
FROM vw_pricewatch_clean
WHERE price IS NOT NULL AND price > 0;

-- 3) Overlap items: items sold by at least 2 retailers (apples-to-apples)
DROP VIEW IF EXISTS vw_overlap_items;
CREATE VIEW vw_overlap_items AS
SELECT product_code
FROM vw_pricewatch_valid
GROUP BY product_code
HAVING COUNT(DISTINCT retailer) >= 2;

-- Recommended quick checks
-- SELECT COUNT(*) FROM pricewatch_raw;
-- SELECT COUNT(*) FROM vw_pricewatch_clean;
-- SELECT COUNT(*) FROM vw_pricewatch_valid;