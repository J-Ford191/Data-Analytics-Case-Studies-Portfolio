![Dashboard Overview](outputs/charts/QLD Fuel Pricing — Local Competition & Repricing Lag (Jan–Jul 2025) (1).png)

# QLD Fuel Pricing — Local Competition & Repricing Lag (Jan–Jul 2025)

**Niche:** Pricing & Revenue Analytics · **Skills:** SQL (SQLite), Tableau

**Live dashboard:** [https://public.tableau.com/views/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link](https://public.tableau.com/views/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## Deliverables

**Mini deck (PPTX):** [docs/QLD_Fuel_Pricing_Mini_Deck.pdf](docs/QLD_Fuel_Pricing_Mini_Deck.pdf)

```

This case study quantifies two pricing levers for Queensland fuel retailers:
- **Local Competitive Position** — share of time a site is the **local** lowest-priced retailer (duration‑weighted).
- **Repricing Speed** — **median minutes** a site takes to react to the latest competitor move in the same suburb & fuel.

---

## Repository Structure

```
sql/
  setup_events_all.sql
  metrics_tables.sql
  controls_log.sql
data/
  processed/
    data_processed_lowest_share_by_site.csv
    data_processed_repricing_lag_by_site.csv
    data_processed_site_locations.csv
outputs/
  charts/
    ws1_scatter.png
    ws2_lowest_share.png
    ws3_repricing_lag.png
    dashboard_overview.png
    QLD Fuel Pricing — Local Competition & Repricing Lag (Jan–Jul 2025) (1).png
LICENSE

```

---

## Business Problem

Retail fuel is fast-moving and highly competitive. Field and pricing teams need clear visibility on:
1) **Competitiveness** — Are we priced to win locally without over‑discounting?  
2) **Responsiveness** — How fast do we react to competitor price moves?

These KPIs support disciplined pricing, surface execution gaps, and guide store‑level coaching.

---

## Data & Lineage

- **Source:** Queensland Government Fuel Price Reporting (changes‑only events).  
- **Window:** 2025‑01 to 2025‑07.  
- **Grain:** One row per **price change event** (`SiteId × Fuel_Type`) with UTC timestamp (`TransactionDateutc`).  
- **Key raw fields:** `SiteId, Site_Name, Site_Brand, Site_Suburb, Site_State, Fuel_Type, Price, TransactionDateutc`.  
- **Units:** `Price` stored in **tenths of cpl**; `9999` denotes unavailable (excluded from price analytics).

### ETL (SQLite)
Run `sql/setup_events_all.sql` to:
- Union monthly staging tables into **`events_all`** (materialized).  
- Deduplicate by `(SiteId, Fuel_Type, TransactionDateutc)` and flag conflicts.  
- Parse **UTC → AEST** (`txn_aest_dt = utc + 10h`) and derive `price_cpl = Price/10.0`.  
- Flag `is_unavailable`, `is_qld`, and conservative `is_outlier` bands by fuel.  
- Create helper tables for interval logic: `ev_intervals`, `t_ticks`, `t_tick_min` and add indexes.

### Metrics (SQL)
Run `sql/metrics_tables.sql` to create:
- **`tbl_repricing_lag_site`** — site‑level **median** & average lag (minutes) vs latest competitor change within `(Site_Suburb, Fuel_Type)`.
- **`tbl_lowest_price_share`** — duration‑weighted share of time a site equals the **local minimum** price at each tick interval.

Exported CSVs in `data/processed/` power the Tableau workbook.

---

## Controls Log (summary)

Run `sql/controls_log.sql` to validate the build:
- **Schema & nulls:** quick null scan on key columns.  
- **Duplicates:** duplicate event keys and conflicting prices flagged.  
- **Ranges & units:** `Price=9999` counts; price cpl bands by fuel; outliers flagged (not deleted).  
- **Integrity:** tick intervals are covered by at least one price interval.

> Keep this script in PRs to document data quality checks with every refresh.

---

## Tableau Views

1) **Local Competitive Position (WS1)** — Scatter: **Avg price (cpl)** vs **Lowest‑price share (%)**.  
2) **Lowest‑Price Share (WS2)** — Sorted bars by site.  
3) **Repricing Lag (WS3)** — Bars of **median lag (minutes)** by site.  
**Filters:** Fuel Type (single), Site Suburb (multi), Site Brand (multi). WS1/WS2 act as **filters** on the dashboard.

Screenshots:
![WS1](outputs/charts/ws1_scatter.png)
![WS2](outputs/charts/ws2_lowest_share.png)
![WS3](outputs/charts/ws3_repricing_lag.png)

---

## Reproduce

1. Create a SQLite DB and import the 7 monthly CSVs as:  
   `stg_qld_fuel_2025_01 … stg_qld_fuel_2025_07`.
2. Execute `sql/setup_events_all.sql` → builds `events_all` (+ indexes, helper tables).  
3. Execute `sql/metrics_tables.sql` → builds the two metrics tables.  
4. Export:
   - `tbl_lowest_price_share` → `data/processed/data_processed_lowest_share_by_site.csv`  
   - `tbl_repricing_lag_site` → `data/processed/data_processed_repricing_lag_by_site.csv`  
   - Distinct site lat/lon → `data/processed/data_processed_site_locations.csv`
5. Open Tableau and connect the three CSVs. Recreate the 3 worksheets and the dashboard layout; or use the live Public link above.

---

## What to Look For

- **Top‑left of WS1** = strong competitive position (low average price, high lowest‑price share).  
- **Long lags** on WS3 flag slow responses; review alerting/approval workflows.  
- Compare brands within the same **fuel** and **suburb** filters to keep like‑for‑like comparisons.

---

## License

MIT © 2025 **Junelle James Ford** — see `LICENSE`.
