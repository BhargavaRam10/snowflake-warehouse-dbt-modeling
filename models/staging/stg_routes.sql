-- Staging: route master, lightly typed.
{{ config(materialized="view") }}

select distinct
    route_id,
    zone,
    truck_id,
    driver_name,
    try_to_number(stops_planned) as stops_planned
from {{ source("ops", "routes_raw") }}
where route_id is not null
