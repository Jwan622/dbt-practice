{{
    config(
        materialized='test'
    )
}}

select * from dbt.valid_and_bookable_routes
WHERE travel_time > '24:00:00'
