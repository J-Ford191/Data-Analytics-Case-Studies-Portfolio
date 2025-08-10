# Tableau Workbook & Repro Notes — HK Online Price Watch

**Put your Tableau workbook here** as a `.twbx` (recommended) so data extracts are packaged for portability.

## Recommended Artifacts
- `HK_OPW_Competitive_Snapshot.twbx` — packaged workbook with 3 views
- `connection_notes.txt` — short note on data sources and refresh steps
- `versioning/` — optional folder if you keep multiple versions

## Data Sources (expected paths)
- `data/interim/category_leaderboard.csv`
- `data/interim/promo_undercut.csv`

## Refresh Steps (quick)
1. Open the `.twbx`.
2. If Tableau asks for files, point to the CSVs above.
3. Verify **filters** for `category_1` are set to the intended categories.
4. Export charts to `charts/` using the agreed naming scheme.

## Views to Keep
1. **Lowest-price share by retailer** (bar) — per category
2. **Average Price Index by retailer** (bar with reference line at 100)
3. **Promo vs Non-promo undercutting** (side-by-side bars)

## Versioning Suggestion
Use date-stamped versions if you re-run this later:
- `HK_OPW_Competitive_Snapshot_2025-08-11.twbx`