-- Staging: service events, lightly typed.
{{ config(materialized="view") }}

select
    event_id,
    route_id,
    try_to_date(event_date)   as event_date,
    upper(trim(event_type))   as event_type,
    upper(trim(priority))     as priority
from {{ source("ops", "service_events_raw") }}
where event_id is not null
  and event_date is not null
