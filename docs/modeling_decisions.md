# Modeling decisions

## Layer conventions

- **Staging** = source-conformed, lightly typed views. One staging model per
  raw table, no joins. Naming: `stg_<source>`. Staging never drops rows except
  on hard quality violations (null natural keys) — those go to quarantine in
  the ingestion layer's silver step instead.
- **Intermediate** = business logic. `int_daily_route_activity` is the only
  place pickup/event aggregation logic lives, so if the missed-pickup
  definition changes, exactly one model changes.
- **Marts** = thin, BI-facing tables in a star schema. Facts hold measures and
  foreign keys; dims hold attributes. `fact_pickups` computes
  `missed_pickup_rate` in SQL so the KPI definition can't drift between
  dashboards.

## Grain choices

- Fact grain is **one row per route per day**, not per pickup. Operations
  questions are answered at route-day level; per-pickup detail stays queryable
  in staging for drill-through without bloating the fact table.
- `dim_date` is generated in-warehouse (Snowflake `generator`) rather than
  seeded, so the calendar has no external dependency and always covers the
  reporting window.

## Slowly changing dimensions

- `dim_route` is SCD **type 1** (overwrite): truck/driver reassignments are
  operational attributes where history is not analytically required. If zone
  history becomes a reporting need, the upgrade path is a type-2
  `dim_route_history` with `valid_from`/`valid_to` — noted in the roadmap.

## Data quality as tests, not hope

- `unique` + `not_null` on every natural key (dbt built-ins, in `schema.yml`).
- `relationships` tests enforce referential integrity: every `route_id` in
  `stg_pickups` must exist in `stg_routes`, every fact row must hit `dim_route`.
- Accepted-values tests on `material` are enforced upstream at ingestion;
  restating them here would duplicate ownership — the contract lives in one
  place (see repo 01, `csv_loader.py`).
