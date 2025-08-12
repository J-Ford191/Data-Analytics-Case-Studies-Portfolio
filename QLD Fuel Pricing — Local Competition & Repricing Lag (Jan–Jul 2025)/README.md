![Dashboard Overview](https://github.com/J-Ford191/Data-Analytics-Case-Studies-Portfolio/blob/main/QLD%20Fuel%20Pricing%20%E2%80%94%20Local%20Competition%20%26%20Repricing%20Lag%20(Jan%E2%80%93Jul%202025)/outputs/charts/QLD%20Fuel%20Pricing%20%E2%80%94%20Local%20Competition%20%26%20Repricing%20Lag%20(Jan%E2%80%93Jul%202025).png)

# QLD Fuel Pricing — Local Competition & Repricing Lag (Jan–Jul 2025)

**Niche:** Pricing & Revenue Analytics · **Skills:** SQL (SQLite), Tableau

**Live dashboard:** [https://public.tableau.com/views/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link](https://public.tableau.com/views/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025/QLDFuelPricingLocalCompetitionRepricingLagJanJul2025?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)  

**Mini deck (PDF):** [docs/QLD_Fuel_Pricing_Mini_Deck.pdf](docs/QLD_Fuel_Pricing_Mini_Deck.pdf)

This case study quantifies two pricing levers for Queensland fuel retailers:
- **Local Competitive Position** — share of time a site is the **local** lowest-priced retailer (duration-weighted).
- **Repricing Speed** — **median minutes** a site takes to react to the latest competitor move in the same suburb & fuel.

---

## Repository Structure

```
qld-fuel-pricing/
├─ sql/
│  ├─ setup_events_all.sql
│  ├─ metrics_tables.sql
│  └─ controls_log.sql
├─ data/
│  └─ processed/
│     ├─ data_processed_lowest_share_by_site.csv
│     ├─ data_processed_repricing_lag_by_site.csv
│     └─ data_processed_site_locations.csv
├─ outputs/
│  └─ charts/
│     ├─ QLD Fuel Pricing — Local Competition & Repricing Lag (Jan–Jul 2025).png
│     ├─ ws1_scatter.png
│     ├─ ws2_lowest_share.png
│     └─ ws3_repricing_lag.png
└─ docs/
   └─ QLD_Fuel_Pricing_Mini_Deck.pptx
```

---

## Business Problem

Retail fuel is fast-moving and highly competitive. Field and pricing teams need visibility on:
1) **Competitiveness** — Are we priced to win locally without over-discounting?  
2) **Responsiveness** — How fast do we react to competitors’ changes?

These KPIs surface execution gaps and guide store-level coaching.

---

## Data & Lineage

- **Source:** Queensland Government Fuel Price Reporting (changes-only events).  
- **Window:** 2025-01 to 2025-07.  
- **Grain:** One row per **price change event** (`SiteId × Fuel_Type`) with UTC timestamp (`TransactionDateutc`).  
- **Units:** `Price` in **tenths of cpl**; `9999` denotes unavailable (excluded).

### ETL (SQLite)
Run `sql/setup_events_all.sql` to:
- Union monthly staging tables into **`events_all`** (materialized).  
- Deduplicate `(SiteId, Fuel_Type, TransactionDateutc)` and flag conflicts.  
- Parse **UTC → AEST** (`txn_aest_dt = utc + 10h`) and derive `price_cpl = Price/10.0`.  
- Flag `is_unavailable`, `is_qld`, and conservative `is_outlier` bands by fuel.  
- Build helper tables for interval logic: `ev_intervals`, `t_ticks`, `t_tick_min` + indexes.

### Metrics (SQL)
Run `sql/metrics_tables.sql` to create:
- **`tbl_repricing_lag_site`** — site-level **median** & average lag (minutes) vs latest competitor change within `(Site_Suburb, Fuel_Type)`.
- **`tbl_lowest_price_share`** — duration-weighted share of time a site equals the **local minimum** price at each tick interval.

Exports in `data/processed/` power the Tableau workbook.

---

## Controls Log (summary)

Run `sql/controls_log.sql` to validate the build:
- Null scan on key columns.
- Duplicates & conflicting prices.
- Price ranges: `Price=9999` counts, min/max `price_cpl` by fuel; outlier flags.
- Integrity: ticks covered by at least one price interval.

---

## Tableau Views

1) **Local Competitive Position** — Scatter: **Avg price (cpl)** vs **Lowest-price share (%)**.  
2) **Lowest-Price Share** — Sorted bars by site.  
3) **Repricing Lag** — Bars of **median lag (minutes)** by site.  
**Filters:** Fuel Type (single), Site Suburb (multi), Site Brand (multi). WS1/WS2 act as **filters** on the dashboard.

Screenshots:

![WS1](https://github.com/J-Ford191/Data-Analytics-Case-Studies-Portfolio/blob/main/QLD%20Fuel%20Pricing%20%E2%80%94%20Local%20Competition%20%26%20Repricing%20Lag%20(Jan%E2%80%93Jul%202025)/outputs/charts/ws1_scatter.png.png)
![WS2](https://github.com/J-Ford191/Data-Analytics-Case-Studies-Portfolio/blob/main/QLD%20Fuel%20Pricing%20%E2%80%94%20Local%20Competition%20%26%20Repricing%20Lag%20(Jan%E2%80%93Jul%202025)/outputs/charts/ws2_lowest_share.png.png)
![WS3](https://github.com/J-Ford191/Data-Analytics-Case-Studies-Portfolio/blob/main/QLD%20Fuel%20Pricing%20%E2%80%94%20Local%20Competition%20%26%20Repricing%20Lag%20(Jan%E2%80%93Jul%202025)/outputs/charts/ws3_repricing_lag.png.png)

---

## Reproduce

1. Import the 7 monthly CSVs as `stg_qld_fuel_2025_01 … stg_qld_fuel_2025_07` into a SQLite DB.  
2. Run `sql/setup_events_all.sql` → builds `events_all` (+ indexes & helpers).  
3. Run `sql/metrics_tables.sql` → builds the two metrics tables.  
4. Export:
   - `tbl_lowest_price_share` → `data/processed/data_processed_lowest_share_by_site.csv`  
   - `tbl_repricing_lag_site` → `data/processed/data_processed_repricing_lag_by_site.csv`  
   - Distinct site lat/lon → `data/processed/data_processed_site_locations.csv`
5. Open Tableau, connect the three CSVs, and use the included dashboard layout.

---

## License

MIT © 2025 **Junelle James Ford** — see `LICENSE`.
