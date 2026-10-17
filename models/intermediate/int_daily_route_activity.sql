-- Intermediate: one row per route per day, joining pickups to routes and
-- attaching service-event counts. Business logic lives here; marts stay thin.
{{ config(materialized="view") }}

with daily_pickups as (
    select
        pickup_date,
        route_id,
        count(*)                                  as pickup_count,
        sum(tonnage)                              as total_tonnage,
        sum(case when material = 'MSW' then tonnage else 0 end)      as msw_tonnage,
        sum(case when material = 'RECYCLE' then tonnage else 0 end)  as recycle_tonnage,
        sum(case when material = 'ORGANICS' then tonnage else 0 end) as organics_tonnage
    from {{ ref("stg_pickups") }}
    group by 1, 2
),

daily_events as (
    select
        event_date,
        route_id,
        count(*) as total_service_events,
        count(case when event_type = 'MISSED_PICKUP' then 1 end) as missed_pickups
    from {{ ref("stg_service_events") }}
    group by 1, 2
)

select
    dp.pickup_date                          as report_date,
    r.route_id,
    r.zone,
    r.truck_id,
    r.driver_name,
    r.stops_planned,
    dp.pickup_count,
    dp.total_tonnage,
    dp.msw_tonnage,
    dp.recycle_tonnage,
    dp.organics_tonnage,
    coalesce(de.total_service_events, 0)    as total_service_events,
    coalesce(de.missed_pickups, 0)          as missed_pickups
from daily_pickups dp
join {{ ref("stg_routes") }} r
    on dp.route_id = r.route_id
left join daily_events de
    on dp.route_id = de.route_id
   and dp.pickup_date = de.event_date
