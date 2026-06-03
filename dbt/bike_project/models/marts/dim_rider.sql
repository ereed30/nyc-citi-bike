{{ config(materialized='table') }}

with rider_types as (

    select 'member' as rider_type, 'Member' as rider_type_label,
           'Annual or monthly subscriber with a recurring membership' as rider_type_description
    union all
    select 'casual', 'Casual',
           'Pay-per-ride or day-pass user without a recurring membership'

)

select * from rider_types