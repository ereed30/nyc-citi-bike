with trips as (

    select * from {{ ref('stg_bikes__trips') }}

),

start_stations as (

    select
        start_station_id   as station_id,
        start_station_name as station_name,
        start_lat          as latitude,
        start_lng          as longitude,
        started_at         as observed_at
    from trips
    where start_station_id is not null

),

end_stations as (

    select
        end_station_id   as station_id,
        end_station_name as station_name,
        end_lat          as latitude,
        end_lng          as longitude,
        ended_at         as observed_at
    from trips
    where end_station_id is not null

),

all_appearances as (

    select * from start_stations
    union all
    select * from end_stations

),

ranked as (

    select
        station_id,
        station_name,
        latitude,
        longitude,
        observed_at,
        row_number() over (
            partition by station_id
            order by observed_at desc
        ) as recency_rank
    from all_appearances
    where station_name is not null

),

geo as (

    select
        station_id,
        station_name,
        latitude,
        longitude
    from ranked
    where recency_rank = 1

),

usage_stats as (

    select
        station_id,
        count(*) as total_appearances,
        sum(case when role = 'start' then 1 else 0 end) as times_as_start,
        sum(case when role = 'end'   then 1 else 0 end) as times_as_end,
        min(observed_at) as first_seen_at,
        max(observed_at) as last_seen_at
    from (
        select start_station_id as station_id, 'start' as role, started_at as observed_at
        from trips
        where start_station_id is not null
        union all
        select end_station_id as station_id, 'end' as role, ended_at as observed_at
        from trips
        where end_station_id is not null
    )
    group by station_id

),

final as (

    select
        g.station_id,
        g.station_name,
        g.latitude,
        g.longitude,
        u.total_appearances,
        u.times_as_start,
        u.times_as_end,
        u.first_seen_at,
        u.last_seen_at
    from 
        geo g
        left join usage_stats u using (station_id)

)

select * from final
order by total_appearances desc