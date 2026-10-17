-- Fact table: one row per route per day. The single source of truth for
-- operations reporting; every BI measure builds on this grain.
{{ config(materialized="table") }}

select
    report_date,
    route_id,
    zone,
    truck_id,
    driver_name,
    stops_planned,
    pickup_count,
    total_tonnage,
    msw_tonnage,
    recycle_tonnage,
    organics_tonnage,
    total_service_events,
    missed_pickups,
    -- headline reliability KPI, computed once in the warehouse (not in DAX)
    div0(missed_pickups, nullif(pickup_count, 0)) as missed_pickup_rate
from {{ ref("int_daily_route_activity") }}
