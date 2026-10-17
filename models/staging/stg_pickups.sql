-- Staging: raw pickup transactions, lightly typed.
-- One row per source pickup. Deduped on pickup_id, keeping the latest load.
{{ config(materialized="view") }}

with source as (
    select * from {{ source("ops", "pickups_raw") }}
),

renamed as (
    select
        pickup_id,
        route_id,
        try_to_date(pickup_date)  as pickup_date,
        try_to_number(tonnage)    as tonnage,
        upper(trim(material))     as material,
        _load_timestamp
    from source
),

deduped as (
    select *,
        row_number() over (
            partition by pickup_id order by _load_timestamp desc
        ) as rn
    from renamed
)

select
    pickup_id,
    route_id,
    pickup_date,
    tonnage,
    material
from deduped
where rn = 1
  and pickup_date is not null
  and tonnage is not null
  and tonnage >= 0
  and material in ('MSW', 'RECYCLE', 'ORGANICS')
