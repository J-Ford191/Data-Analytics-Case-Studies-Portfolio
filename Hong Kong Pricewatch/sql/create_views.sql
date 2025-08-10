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

DROP VIEW IF EXISTS vw_pricewatch_valid;
CREATE VIEW vw_pricewatch_valid AS
SELECT *
FROM vw_pricewatch_clean
WHERE price IS NOT NULL AND price > 0;
