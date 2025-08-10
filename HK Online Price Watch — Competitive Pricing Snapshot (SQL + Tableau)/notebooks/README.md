# Notebooks Runbook — HK Online Price Watch (SQL + Tableau)

**Purpose:** Keep a clear, linear record of what you ran and why, so stakeholders (and future-you) can reproduce or audit the work.

## Suggested Files to Keep Here
- `SQL_Runbook.md` — ordered list of SQL you executed (with brief notes).
- `EDA_Snapshot_Log.md` — quick notes on data checks, row counts, anomalies.
- *(Optional)* `Pricewatch_Exploration.ipynb` — if you ever switch to Python for light checks/plots.

---

## Template: `SQL_Runbook.md`
Use this structure when you paste SQL you actually ran (in order):

```
# SQL Runbook
Date: 2025-08-10

## 1) Import
- Tool: sqliteonline.com
- Table created: pricewatch_raw
- Rows imported: <paste count>

## 2) Cleaning Views
-- Paste the actual `create_views.sql` blocks you ran
-- Note any edits if diverged from repo

## 3) Analysis Views
-- Paste the actual `analysis_views.sql` blocks you ran

## 4) Extracts
- category_leaderboard.csv: generated via query <paste>
- promo_undercut.csv: generated via query <paste>

## 5) Checks
- Overlap items (>=2 retailers): <paste counts>
- Price range (valid rows): <paste>

## 6) Decisions / Notes
- Categories selected: Personal care, Noodles..., Candies..., Drinks
- Any caveats or anomalies
```

---

## Template: `EDA_Snapshot_Log.md`
Use this to record quick sanity checks on the exact CSV snapshot you used.

```
# EDA Snapshot Log
Date: 2025-08-10
File: data/raw/pricewatch_en.csv

Row counts:
- raw_rows: <value>
- clean_rows: <value>
- valid_rows: <value>

Retailer coverage (valid):
- <retailer>: <n>
- ...

Top categories (valid):
- <cat1>: <n>
- ...

Promos:
- promo_flag=1: <n>
- promo_flag=0: <n>

Notes:
- Any parsing oddities, zeros, etc.
```