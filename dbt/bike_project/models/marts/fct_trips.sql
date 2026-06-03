with trips as (

    select * from {{ ref('stg_bikes__trips') }}

),

formatted as (

    select
        -- primary key
        ride_id

        -- station foreign keys
        ,start_station_id
        ,end_station_id

        -- date split (foreign key to dim_time)
        ,cast(started_at as date)                       as start_date
        ,cast(ended_at   as date)                       as end_date

        -- time-of-day split (foreign key to dim_time_of_day; truncated to minute)
        ,time_trunc(cast(started_at as time), minute)   as start_time
        ,time_trunc(cast(ended_at   as time), minute)   as end_time

        -- duration
        ,ride_duration_seconds
        ,ride_duration_seconds / 60.0                   as ride_duration_minutes

        -- ride attributes
        ,bike_type
        ,rider_type

    from trips

)

select * from formatted