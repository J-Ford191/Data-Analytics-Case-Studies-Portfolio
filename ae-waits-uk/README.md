# Cutting 12‑Hour Waits in NHS A&E (England)
Provider‑level analysis of A&E attendances and waits using NHS England monthly publications and ECDS supplementary data (2022–2025).

## Business Problem
**How can A&E providers reduce 12‑hour waits and lift 4‑hour performance by Q4 FY2025/26 _without adding headcount_?**

## Decision Targets
- +3–5 pp improvement in **% seen ≤4 hours** at selected trusts.
- −20% in **12‑hours-from-arrival** breaches (Type 1 & 2).
- Evidence‑based action shortlist (SDEC hours, UTC streaming, discharge pull at peak times).

## KPIs (definitions aligned to NHSE)
- **% within 4 hours** = `within_4h_count / total_attendances`
- **12h-from-arrival rate (Type 1+2)** = `arrivals_12h_or_more / type1_2_attendances`
- **Over‑4h after DTA rate** = `over4h_after_dta / emergency_admissions`
- **Admission conversion** = `emergency_admissions / type1_2_attendances`

## Stack
- **SQL (DuckDB/Postgres)**: KPI views, time-series deltas, benchmarks
- **Python (pandas, matplotlib)**: EDA & chart exports to `/charts` (always `.savefig()`)
- **Tableau**: KPI dashboard + breach heatmap + provider scatter

## Repo Structure
```
ae-waits-uk/
├─ README.md
├─ data_description.md
├─ data/
│  ├─ raw/              # original NHS England files
│  └─ processed/        # cleaned CSV/Parquet for analysis & Tableau
├─ notebooks/
│  ├─ 01_download_and_clean.ipynb
│  ├─ 02_eda_kpis.ipynb
│  └─ 03_tableau_extracts.ipynb
├─ sql/
│  ├─ 00_schema.sql
│  ├─ 10_staging_load.sql
│  ├─ 20_kpi_views.sql
│  └─ 30_provider_benchmarks.sql
└─ charts/
   └─ (exported .png via plt.savefig)
```

## How to Reproduce
1) Create a virtual environment and install deps:
   ```bash
   pip install -r requirements.txt
   ```
2) Download latest NHS England monthly **A&E Attendances & Emergency Admissions** and **ECDS Supplementary** files to `data/raw/`.
3) Run notebooks **in order**:
   - `01_download_and_clean.ipynb` → produces tidy CSVs in `data/processed/`
   - `02_eda_kpis.ipynb` → saves charts into `charts/`
   - `03_tableau_extracts.ipynb` → exports curated extracts for Tableau
4) Publish Tableau dashboard (optional) and link it here.

## Insights (to fill after analysis)
- National **%≤4h: [XX%]** (Δ vs LY: [±pp]), **12h-from-arrival: [YY%]** (Δ vs LY: [±pp]).
- **Top improvers** (last 6 months): […].
- **Breach anatomy:** [time-of-day], [DTA/boarding share], [65+ & frailty contributions].

## Notes
- Ensure all figures created in notebooks are exported with `plt.savefig("charts/<name>.png", dpi=200, bbox_inches="tight")`.
