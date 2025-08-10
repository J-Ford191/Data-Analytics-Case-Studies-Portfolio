# HK Online Price Watch — Competitive Pricing Snapshot (SQL + Tableau)

**Author:** Junelle James Ford  
**Created:** 2025-08-10

## Business Framing (to fill)
- Objective: Identify which retailers are most price-competitive by category and whether promotions undercut competitors.
- Snapshot: This dataset is a single-day export (no `date` column). For trends, automate daily capture.

## Skill Focus
- **SQL (SQLite)** for cleaning and metrics
- **Tableau** for business-ready visuals

## Dataset
- Source: Hong Kong Consumer Council — Online Price Watch (daily snapshot)  
  - CSV (EN): https://online-price-watch.consumer.org.hk/opw/opendata/pricewatch_en.csv  
  - Data dictionary (PDF): https://online-price-watch.consumer.org.hk/opw/opendata/pricewatch_data_dictionary.pdf

## Folder Structure
```
hk-pricewatch-sql-tableau/
├─ data/
│  ├─ raw/        # original downloads (do NOT commit large files)
│  └─ interim/    # cleaned/exports for viz
├─ sql/           # DDL/DML & analysis views
├─ charts/        # exported PNGs
├─ notebooks/     # scratch/notes (optional)
└─ presentation/  # slide deck exports
```

## Repro (minimal)
1. Import CSV into SQLite as `pricewatch_raw` (first row header). Use https://sqliteonline.com/ if preferred.
2. Run `sql/create_views.sql` then `sql/analysis_views.sql`.
3. Export two tables for Tableau:
   - Category Leaderboard: join `vw_cat_lowest_share` and `vw_cat_price_index`
   - Promo Undercutting: `vw_cat_promo_undercut`
4. Build three Tableau views and export PNGs into `/charts`:
   - Lowest-price share by retailer
   - Average Price Index vs 100
   - Promo vs Non‑promo undercutting

## Notes
- Tie-handling: lowest-price share is split equally among retailers tied at the minimum price for each item.
- Outliers: review very high-ticket items; optionally cap when story requires.

## License
MIT — see `LICENSE`.
