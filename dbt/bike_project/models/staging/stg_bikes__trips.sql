with source as (

    select * from {{ source('bikes', 'trips_test') }}

),

renamed as (

    select
        -- ids
        ride_id,
        start_station_id,
        end_station_id,

        -- timestamps (raw is VARCHAR, cast to actual timestamps)
        cast(started_at as timestamp) as started_at,
        cast(ended_at   as timestamp) as ended_at,

        -- derived: ride duration in seconds (handy and cheap)
        datediff('second',
                 cast(started_at as timestamp),
                 cast(ended_at   as timestamp)) as ride_duration_seconds,

        -- ride attributes
        rideable_type as bike_type,
        member_casual as rider_type,

        -- station info
        start_station_name,
        end_station_name,

        -- geo
        start_lat,
        start_lng,
        end_lat,
        end_lng,

        -- ingestion metadata
        source_period

    from source

)

select * from renamed