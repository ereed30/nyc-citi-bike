with source as (

    select * from {{ source('bikes', 'citi_bike_raw') }}

),

formatted as (

    select
        -- ids
        ride_id
        , start_station_id
        , end_station_id

        -- timestamps (raw is STRING, cast to actual timestamps)
        , cast(started_at as timestamp) as started_at
        , cast(ended_at   as timestamp) as ended_at

        -- derived: ride duration in seconds (handy and cheap)
        , timestamp_diff(
            cast(ended_at   as timestamp),
            cast(started_at as timestamp),
            second
            ) as ride_duration_seconds

        -- ride attributes
        , rideable_type as bike_type
        , member_casual as rider_type

        -- station info
        , start_station_name
        , end_station_name

        -- geo
        , start_lat
        , start_lng
        , end_lat
        , end_lng

        -- ingestion metadata
        , `month` as monthly_file_partition
        , city

    from source
)


select * from formatted