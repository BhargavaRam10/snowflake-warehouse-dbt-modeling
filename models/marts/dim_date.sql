-- Date dimension generated in-warehouse (no source dependency).
{{ config(materialized="table") }}

with dates as (
    select dateadd(day, seq4(), '2026-01-01') as date_day
    from table(generator(rowcount => 730))
)

select
    date_day                                   as date,
    year(date_day)                             as year,
    month(date_day)                            as month,
    day(date_day)                              as day,
    dayname(date_day)                          as day_name,
    weekofyear(date_day)                       as week_of_year,
    case when dayofweek(date_day) in (0, 6)    -- Snowflake: 0=Sunday
         then true else false end               as is_weekend
from dates
