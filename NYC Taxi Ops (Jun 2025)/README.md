# NYC Taxi Ops — June 2025
Operational snapshot of NYC **Yellow Taxi** trips in **June 2025**.  
Focus: when & where rides happened, peak windows, and revenue mix — packaged as a reproducible mini‑case for a General BA portfolio.

> Dashboard (Tableau Public): **https://public.tableau.com/views/NYCTaxiOpsJun2025/NYCTaxiOpsJun2025**  
> One‑pager (PDF): `docs/nyc_taxi_ops_202506_1pager.pdf`  
> Report (PDF): `docs/nyc_taxi_ops_202506_v1.pdf`

---

## TL;DR (exec view)
- **Evening commute dominates**: **17–18h** account for the peak revenue & trip share in Jun‑2025.
- **Airport & Midtown corridors** lead pickups; **JFK + LaGuardia + Midtown Center** are consistently top‑grossing pickup zones.
- A simple **Pareto** shows ~20–25 zones drive ~80% of revenue → strong candidate set for ops focus (supply balancing, driver comms, pricing tests).
- Cleaned data + controls log ensure we exclude bad durations, out‑of‑range fares, and duplicate keys.

---

## Audience & problem
- **Audience**: Ops managers, city mobility leads, and analysts who need a fast benchmark of taxi demand patterns.
- **Problem**: Identify **when** (hour × day) and **where** (pickup zone) demand & revenue concentrate; produce an explainable, quality‑checked dataset and publish an interactive dashboard for exploration.

---

## Data
- **Primary**: NYC TLC Yellow Taxi (Jun‑2025) — parquet (source: TLC/Kaggle).  
  Example raw file name: `data/raw/nyc_taxi_yellow_2025-06.parquet` *(heavy → recommended to keep outside Git)*.
- **Lookup**: `taxi_zone_lookup` (Borough/Zone names).
- **Processed (local)**: 
  - `data/processed/nyc_taxi_yellow_2025-06_clean.parquet` *(~66MB, optional in Git)*
  - `data/processed/nyc_taxi_yellow_2025-06_clean_with_zones.xlsx` *(~477MB, **exclude from Git**)*

> This repo favors **reproducibility** over storing large binaries: you can rebuild processed files from the notebook.

---

## Methods (sketch)
1. **Load** raw parquet using `pyarrow`.
2. **Derive features**: `trip_minutes`, `pickup_hour`, `pickup_dow`, `tip_rate` (`tip_amount / total_amount`), etc.
3. **QC filters** (plausibility & de‑dupe):
   - `total_amount > 0`, `fare_amount > 0`
   - `passenger_count ∈ [1, 6]`
   - `trip_minutes ∈ [1, 360]` and `trip_distance ∈ (0.85, 100]`
   - drop duplicates on `VendorID + tpep_pickup_datetime + tpep_dropoff_datetime + PULocationID + DOLocationID`
4. **Join names** via `taxi_zone_lookup` → Borough & Zone.
5. **Aggregate** KPIs for charts & tables:
   - Hourly trips/revenue, hour×DOW heatmap, top pickup zones, evening peak (15–19) leaderboard.
6. **Publish** clean parquet + pictures for the deck/dashboard.

> A small **controls log** table (Excel) summarizes each business rule, counts, and a sample of affected rows.

---

## Key findings (June 2025)
- **Peak window**: 17:00–18:59 drives the **largest share of trips & revenue**.
- **Top pickup zones**: JFK, LaGuardia, Midtown Center, Upper East Side (South/North), Times Sq/ Theatre District, Penn Station/Madison Sq — **consistent across views**.
- **Pareto**: Roughly the **top 20–25 zones** account for ~**80%** of revenue → a focused set for ops actions.
- **Demand cadence**: Clear **AM trough** → sharp **PM build** from 15:00 onwards; weekends show flatter profiles.

### Hero visuals (exported)
- `outputs/charts/KPI Summary.png`
- `outputs/charts/Revenue Trend.png`
- `outputs/charts/Pickup Zone.png`
- `outputs/charts/Pareto (Pickup Zone).png`
- Plus hour heatmap & ancillary charts in `outputs/charts/`

---

## Repository layout (what you actually have)
```
NYC Taxi Ops (Jun 2025)/
├─ dashboards/
│  └─ NYC Taxi Ops — Jun 2025.twbx        # very large → don’t commit to GitHub
├─ data/
│  ├─ raw/
│  │  ├─ nyc_taxi_yellow_2025-06.parquet  # heavy → keep outside Git if possible
│  │  └─ taxi_zone_lookup.*               # tiny; safe to keep
│  └─ processed/
│     ├─ nyc_taxi_yellow_2025-06_clean.parquet
│     └─ nyc_taxi_yellow_2025-06_clean_with_zones.xlsx  # huge → exclude
├─ docs/
│  ├─ nyc_taxi_ops_202506_1pager.pdf
│  └─ nyc_taxi_ops_202506_v1.pdf
├─ notebooks/
│  └─ nyc-taxi-ops-jun-2025.ipynb
└─ outputs/
   ├─ charts/
   │  ├─ KPI Summary.png
   │  ├─ Revenue Trend.png
   │  ├─ Pickup Zone.png
   │  ├─ Pareto (Pickup Zone).png
   │  └─ … other exported PNGs
   └─ tables/
      ├─ controls_log_202506.xlsx
      ├─ hour_kpis_202506.xlsx
      ├─ hour_dow_matrix_202506.xlsx
      └─ evening_peak_zone_kpis_202506.xlsx
```

> If you prefer a clean “code‑only” repo, keep: `notebooks/`, `outputs/`, `docs/` and the small `taxi_zone_lookup`. Leave big data & `.twbx` out.

---

## Dashboard (public)
- **Live dashboard**: https://public.tableau.com/views/NYCTaxiOpsJun2025/NYCTaxiOpsJun2025  
  *(The packaged `.twbx` can be stored off‑repo; link above is the source of truth.)*

**Packaging tip** (local, optional): export images from Tableau (`Worksheet → Export → Image`) to `outputs/charts/` and save a packaged workbook to `dashboards/` — but **do not commit the `.twbx`** to GitHub.

---

## How to reproduce
### Option A — Local (Python)
1. Clone the repo and create an env:
   ```bash
   python -m venv .venv && . .venv/Scripts/activate  # Windows
   pip install pandas pyarrow matplotlib openpyxl
   ```
2. Place raw parquet under `data/raw/` and the `taxi_zone_lookup` file next to it.
3. Open and run: `notebooks/nyc-taxi-ops-jun-2025.ipynb`  
   This will create processed parquet(s) and export charts/tables into `outputs/`.

### Option B — Kaggle
1. Upload the notebook to **Kaggle Notebooks**.
2. Attach the Kaggle dataset for *NYC Yellow Taxi Jun‑2025* (or upload your parquet), plus the zone lookup.
3. Run all cells. Download artifacts to your local `outputs/` and `docs/` folders if desired.

---

## Controls log (QA highlights)
| Check | Action |
|---|---|
| `total_amount ≤ 0` or `fare_amount ≤ 0` | drop |
| `passenger_count ∉ [1,6]` | drop |
| `trip_minutes ∉ [1,360]` or `trip_distance ≤ 0.85` or `> 100` | drop |
| Duplicate on key | drop |

The Excel **controls log** in `outputs/tables/` lists rule names, counts, and sample rows.

---

## Limitations & next steps
- Single month snapshot → extend to 3–6 months for seasonality.
- Taxi zones are coarse; consider **hexagon grids** or **OSM POIs** for richer geospatial features.
- Add model‑ready features (weather, events) and test simple **uplift** or **allocation** policies for evening peaks.

---

## Git hygiene (large files)
- Avoid committing: `.twbx`, raw & wide processed datasets.
- Use `.gitignore` (include patterns for `*.twbx`, `*.parquet`, `*.zip`, large `.xlsx`).  
- Keep only **READMEs, notebook, charts, tables (small), docs** in Git; store heavy artifacts in Drive/S3 and link here.

---

## Packaging (optional ZIP for sharing)
If you need a distributable bundle (without raw data):

**PowerShell (Windows)**
```powershell
$paths = @('docs','outputs','notebooks')
Compress-Archive -Path $paths -DestinationPath nyc_taxi_ops_202506_bundle_v2.zip -Force
```

**Bash (macOS/Linux)**
```bash
zip -r nyc_taxi_ops_202506_bundle_v2.zip docs outputs notebooks
```

---

## Credits & license
- Data © NYC Taxi & Limousine Commission (TLC) / Kaggle mirror.
- This repo is for educational/portfolio use. See TLC license before production use.
