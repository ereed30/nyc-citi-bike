{{ config(materialized='table') }}

with bike_type as (

    select 'classic_bike' as bike_type, 'Classic Bike' as bike_type_label,
           'Classic Pedal bike' as bike_type_description
    union all
    select 'electric_bike', 'Electric Bike',
           'e-Bike with pedal assist'

)

select * from bike_type