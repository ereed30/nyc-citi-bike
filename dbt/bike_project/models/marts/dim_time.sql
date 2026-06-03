{{ config(materialized='table') }}

with minute_spine as (

    -- 1,440 minutes in a day (0 through 1439)
    select minute_of_day
    from unnest(generate_array(0, 1439)) as minute_of_day

),

calcs as (

    select
        -- the canonical time value (00:00:00 through 23:59:00 UTC)
        time_add(time '00:00:00', interval minute_of_day minute) as time_of_day,

        -- raw integers
        minute_of_day                                              as minute_of_day,           -- 0-1439
        cast(floor(minute_of_day / 60) as int64)                   as hour,                    -- 0-23
        mod(minute_of_day, 60)                                     as minute,                  -- 0-59

        -- common rollup buckets
        cast(floor(minute_of_day / 15) as int64)                   as quarter_hour_of_day,     -- 0-95
        cast(floor(minute_of_day / 30) as int64)                   as half_hour_of_day         -- 0-47

    from minute_spine

),

labeled as (

    select
        time_of_day,
        minute_of_day,
        hour,
        minute,
        quarter_hour_of_day,
        half_hour_of_day,

        -- text labels
        format_time('%H:%M',    time_of_day)                       as time_hhmm,               -- "11:01"
        format_time('%H:%M:%S', time_of_day)                       as time_hhmmss,             -- "11:01:00"
        format_time('%I:%M %p', time_of_day)                       as time_12h,                -- "11:01 AM"
        concat(lpad(cast(hour as string), 2, '0'), ':00')          as hour_label,              -- "11:00"

        -- time-of-day buckets
        case
            when hour <  5  then 'Late Night'    -- 00:00 - 04:59
            when hour <  9  then 'Early Morning' -- 05:00 - 08:59
            when hour < 12  then 'Morning'       -- 09:00 - 11:59
            when hour < 13  then 'Noon'          -- 12:00 - 12:59
            when hour < 17  then 'Afternoon'     -- 13:00 - 16:59
            when hour < 20  then 'Evening'       -- 17:00 - 19:59
            else                'Night'          -- 20:00 - 23:59
        end                                                        as day_part,

        -- 4-hour shift labels (operational)
        case
            when hour <  6 then '00:00-05:59'
            when hour < 12 then '06:00-11:59'
            when hour < 18 then '12:00-17:59'
            else                '18:00-23:59'
        end                                                        as shift,

        -- AM/PM
        case when hour < 12 then 'AM' else 'PM' end                as am_pm,

        -- commute flags (BigQuery requires parens around BETWEEN when aliased as a boolean)
        (hour between 7  and 9)                                    as is_morning_commute,
        (hour between 16 and 18)                                   as is_evening_commute,
        (hour >= 22 or hour < 5)                                   as is_late_night_hours,
        (hour between 12 and 13)                                   as is_lunch_hour

    from calcs

)

select * from labeled
order by minute_of_day