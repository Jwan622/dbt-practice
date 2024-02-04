{{
    config(
        materialized='test',
    )
}}

select * from dbt.valid_and_bookable_routes
WHERE origin_airport_code = destination_airport_code
OR origin_airport_code = transfer_airport_code
OR destination_airport_code = transfer_airport_code
