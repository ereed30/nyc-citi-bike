-- models/marts/reporting_rides.sql
{{ config(materialized='view') }}

select
    -- from fct_trips
    f.ride_id,
    f.start_date,
    f.start_time,
    f.bike_type,
    f.rider_type,
    f.ride_duration_minutes,

    -- from dim_stations (start)
    s_start.station_name as start_station_name,
    s_start.latitude     as start_lat,
    s_start.longitude    as start_lng,

    -- from dim_stations (end)
    s_end.station_name   as end_station_name,
    s_end.latitude       as end_lat,
    s_end.longitude      as end_lng,

    -- from dim_time
    t.day_name,
    t.month_name,
    t.year_month,
    t.is_weekend,

    -- from dim_time_of_day
    tod.day_part,
    tod.hour,
    tod.is_morning_commute,
    tod.is_evening_commute

from {{ ref('fct_trips') }} f
    left join {{ ref('dim_stations')    }} s_start on f.start_station_id = s_start.station_id
    left join {{ ref('dim_stations')    }} s_end   on f.end_station_id   = s_end.station_id
    left join {{ ref('dim_date')        }} t       on f.start_date       = t.date_day
    left join {{ ref('dim_time') }} tod     on f.start_time       = tod.time_of_day