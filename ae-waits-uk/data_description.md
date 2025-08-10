# Data Description — NHS A&E Attendances & Waits (England)

**Primary source:** NHS England — A&E Attendances and Emergency Admissions (Monthly).  
Provider-level monthly fields: total attendances (all A&E types), number within 4 hours, emergency admissions, waits >4h after decision to admit (DTA).

**Supplementary source:** Emergency Care Data Set (ECDS) — Monthly Supplementary Analysis.  
Fields: Type 1/2 attendances, **12h-from-arrival** counts, age/sex/ethnicity/chief complaint; **frailty (CFS) from 12 Dec 2024**; provider/system/national.

**Notes & caveats**
- 12h-from-arrival applies to Type 1 & 2 attendances (excludes UTC-only units).
- Definitions follow NHSE statistical publications and technical specs.
- Some early historical series are derived/estimated; treat accordingly.

**Refresh cadence:** Monthly (typically 2nd Thursday).

**Column Guide (processed outputs)**
- `provider_code` — NHSE provider code
- `provider_name` — official provider name
- `month_date` — month end date (YYYY-MM-01 recommended for month index)
- `total_attendances`
- `within_4h_count`
- `emergency_admissions`
- `over4h_after_dta`
- `type12_attendances` (ECDS)
- `arrivals_12h_or_more` (ECDS)
- Derived:
  - `pct_within_4h`
  - `rate_12h_from_arrival`
  - `admit_conversion`
  - `over4h_dta_rate`
