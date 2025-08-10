# HK Online Price Watch — Competitive Pricing Snapshot (SQL + Tableau)

**Skill focus:** SQL + Tableau  
**Domain:** Retail / E‑commerce pricing  
**Snapshot date:** *Single‑day snapshot (dataset has no date field; see “Limitations & Next Steps”)*

---

## 1) Business Problem
Category managers need to understand **which retailers are most price‑competitive by category** and whether **promotions** materially undercut competitors on comparable items.

## 2) Key Questions
1. Which retailer has the **lowest average price share** by category (based on items sold by ≥2 retailers)?  
2. What is each retailer’s **Average Price Index** by category (Retailer price ÷ Item’s market average × 100)?  
3. Do **promoted** items undercut competitors more often than **non‑promoted** items?

## 3) Dataset
**Source:** Hong Kong Consumer Council — Online Price Watch (CSV, updated frequently).  
- CSV: `pricewatch_en.csv` (placed in `data/raw/`)  
- Fields (per source dictionary): Category_1/2/3, Product_Code, Brand, Product_Name, Supermarket_Code, Price, Offers.  
- Notes: The public CSV is a **daily snapshot** without a date column. Time‑series analysis requires daily capture.

> Attribution: Data provided by the Hong Kong Consumer Council (Online Price Watch). All rights remain with the original data owner and are used here for analysis/education.

## 4) Repository Structure
```
data/
  raw/        # Original downloads (CSV, dictionary PDF)
  interim/    # Cleaned/extracted CSVs for Tableau (e.g., category_leaderboard.csv, promo_undercut.csv)
sql/          # SQL scripts to create views and analysis outputs
charts/
  lowest_share/
  price_index/
  promo_undercut/
tableau/      # Tableau workbook (.twb/.twbx) if saved
docs/         # Short slide deck / write-up
notebooks/    # Optional scratch notes
README.md
```

## 5) Method (Christine Jiang style)
**Framing → Explore/Clean → Analyze → Share**
- **Explore/Clean:** Standardize fields, cast prices, derive `promo_flag`, drop non‑positive prices; focus on items sold by ≥2 retailers (apples‑to‑apples).  
- **Analyze (SQL):**  
  - Compute item‑level **Price Index** vs. item average.  
  - Aggregate to category‑retailer **Avg Price Index**.  
  - Compute **Lowest‑price share** (tie‑weighted).  
  - Compare **Promo vs Non‑promo undercutting**.
- **Share (Tableau):** Three concise views per category: Lowest‑price share, Avg Price Index, Promo vs Non‑promo undercutting.

## 6) Reproducibility (SQLite + Tableau)
### A) SQLite
1. Import `data/raw/pricewatch_en.csv` into a table named **`pricewatch_raw`** (via sqliteonline.com import or SQLite CLI).  
2. Run scripts in order:
   - `sql/create_views.sql`
   - `sql/analysis_views.sql`
3. Export analysis extracts (already provided in `data/interim/`, but you can regenerate):
   - **Category leaderboard** (join of lowest‑price share + price index).  
   - **Promo undercutting** (promo vs non‑promo rates).
   > Tip: In SQLite CLI you can export as CSV with:
   > ```
   > .headers on
   > .mode csv
   > .output data/interim/category_leaderboard.csv
   > SELECT c.category_1, c.retailer, c.lowest_share_pct, c.n_items, p.avg_price_index
   > FROM vw_cat_lowest_share c
   > JOIN vw_cat_price_index p
   >   ON p.category_1 = c.category_1 AND p.retailer = c.retailer
   > ORDER BY c.category_1, c.lowest_share_pct DESC;
   > .output stdout
   > ```

### B) Tableau
- Connect to `data/interim/category_leaderboard.csv` and `data/interim/promo_undercut.csv`.  
- Views (one category at a time; exported to `charts/`):
  1. **Lowest‑price share by retailer** (bar chart)  
  2. **Average Price Index by retailer** (bar chart with a 100 reference line)  
  3. **Promo vs Non‑promo undercutting** (side‑by‑side bars)

## 7) KPIs & Definitions
- **Price Index (item‑retailer)** = 100 × Retailer price ÷ Average price of the same item across retailers.  
- **Avg Price Index (category‑retailer)** = Mean of item‑level indices for items sold by ≥2 retailers in that category.  
- **Lowest‑price share** = Proportion of overlapping items where a retailer ties for the **lowest price** (ties split evenly).  
- **Promo undercutting** = % of overlapping items where the retailer is lowest while `promo_flag = 1` vs when `promo_flag = 0`.

## 8) Limitations & Next Steps
- **Single‑day snapshot:** No date column in the source CSV. For trends, schedule a daily fetch and append a snapshot date column.  
- **Assortment differences:** Results consider only items sold by ≥2 retailers; exclusive items are excluded.  
- **Text normalization:** Minor brand/name inconsistencies can affect item matching; the dataset uses a provided product code to mitigate this.

**Planned extensions**
- Automate **daily ingestion** with a snapshot date → build time‑series price index.  
- Add **unit/pack normalization** for like‑for‑like comparisons.  
- Publish a public **Tableau dashboard** once time‑series is in place.

---

**Prepared by:** Junelle James Ford  
**Last updated:** 2025-08-10