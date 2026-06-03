{{ config(materialized='table') }}

with date_range as (

    -- One row per day for the last 12 months
    select
        date_add(
            date_sub(current_date(), interval 12 month),
            interval offset day
        ) as date_day
    from unnest(generate_array(
        0,
        date_diff(current_date(), date_sub(current_date(), interval 12 month), day)
    )) as offset

),

calcs as (

    select
        date_day

        -- numeric parts
        ,extract(year      from date_day) as year
        ,extract(quarter   from date_day) as quarter
        ,extract(month     from date_day) as month
        ,extract(week      from date_day) as week_of_year
        ,extract(day       from date_day) as day_of_month
        ,extract(dayofyear from date_day) as day_of_year
        ,extract(dayofweek from date_day) as day_of_week     -- BQ: 1=Sun, 7=Sat

        -- text labels
        ,format_date('%A',    date_day) as day_name
        ,format_date('%a',    date_day) as day_name_short
        ,format_date('%B',    date_day) as month_name
        ,format_date('%b',    date_day) as month_name_short
        ,format_date('%Y-%m', date_day) as year_month
        ,concat(
            'Q', cast(extract(quarter from date_day) as string),
            ' ', cast(extract(year from date_day) as string)
         ) as year_quarter

        -- period boundaries
        ,date_trunc(date_day, week)    as week_start_date
        ,date_trunc(date_day, month)   as month_start_date
        ,date_sub(
            date_add(date_trunc(date_day, month), interval 1 month),
            interval 1 day
         ) as month_end_date
        ,date_trunc(date_day, quarter) as quarter_start_date
        ,date_trunc(date_day, year)    as year_start_date

        -- boolean flags
        ,extract(dayofweek from date_day) in (1, 7)     as is_weekend
        ,extract(dayofweek from date_day) not in (1, 7) as is_weekday

        -- relative-to-today helpers
        ,date_day = current_date()                                                                as is_today
        ,date_day = date_sub(current_date(), interval 1 day)                                      as is_yesterday
        ,date_day >= date_sub(current_date(), interval 7  day) and date_day < current_date()      as is_last_7_days
        ,date_day >= date_sub(current_date(), interval 30 day) and date_day < current_date()      as is_last_30_days
        ,date_day >= date_trunc(current_date(), month)                                            as is_current_month
        ,date_day >= date_trunc(current_date(), year)                                             as is_current_year

    from date_range

)

select * from calcs
order by date_day