-- Slowly changing dimension (type 1): current route attributes.
{{ config(materialized="table") }}

select distinct
    route_id,
    zone,
    truck_id,
    driver_name,
    stops_planned
from {{ ref("stg_routes") }}
