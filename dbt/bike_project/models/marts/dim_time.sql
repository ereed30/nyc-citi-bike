{{ config(materialized='table') }}

with date_range as (

    -- One row per day for the last 12 months through today.
    select
        cast(current_date - interval 12 month as date) + interval (i) day as date_day
    from range(
        0,
        (current_date - cast(current_date - interval 12 month as date))::int + 1
    ) as t(i)

),

calcs as (

    select
        cast(date_day as date) as date_day

        -- numeric parts
        ,extract('year'    from date_day)::int as year
        ,extract('quarter' from date_day)::int as quarter
        ,extract('month'   from date_day)::int as month
        ,extract('week'    from date_day)::int as week_of_year
        ,extract('day'     from date_day)::int as day_of_month
        ,extract('doy'     from date_day)::int as day_of_year
        ,extract('dow'     from date_day)::int as day_of_week

        -- text labels
        ,strftime(date_day, '%A')    as day_name
        ,strftime(date_day, '%a')    as day_name_short
        ,strftime(date_day, '%B')    as month_name
        ,strftime(date_day, '%b')    as month_name_short
        ,strftime(date_day, '%Y-%m') as year_month
        ,('Q' || extract('quarter' from date_day)::varchar
            || ' ' || extract('year' from date_day)::varchar) as year_quarter

        -- period boundaries
        ,date_trunc('week',    date_day)::date as week_start_date
        ,date_trunc('month',   date_day)::date as month_start_date
        ,(date_trunc('month',  date_day) + interval 1 month - interval 1 day)::date as month_end_date
        ,date_trunc('quarter', date_day)::date as quarter_start_date
        ,date_trunc('year',    date_day)::date as year_start_date

        -- boolean flags
        ,extract('dow' from date_day) in (0, 6)     as is_weekend
        ,extract('dow' from date_day) not in (0, 6) as is_weekday

        -- relative-to-today helpers
        ,date_day = current_date                                                as is_today
        ,date_day = current_date - interval 1 day                               as is_yesterday
        ,date_day >= current_date - interval 7  day and date_day < current_date as is_last_7_days
        ,date_day >= current_date - interval 30 day and date_day < current_date as is_last_30_days
        ,date_day >= date_trunc('month', current_date)                          as is_current_month
        ,date_day >= date_trunc('year',  current_date)                          as is_current_year

    from date_range

)

select * from calcs
order by date_day