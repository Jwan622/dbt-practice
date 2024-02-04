-- we want null values in the second_flight_no column because we DO want to include single leg flights... I think. Those are valid too

{{ config(
    materialized='test'
) }}

with are_there_single_leg_flights_or_not as (
    SELECT
        CASE
            WHEN COUNT(*) = 0 THEN 'Column is always non-null'
            WHEN SUM(CASE WHEN second_flight_no IS NULL THEN 1 ELSE 0 END) > 0 THEN 'Column has null values'
            ELSE 'Column is always non-null'
        END AS test_result
    FROM dbt.valid_and_bookable_routes
)
SELECT *
FROM are_there_single_leg_flights_or_not
WHERE test_result = 'Column is always non-null'
-- this returns a row, causing dbt to fail, if the column is always non-null, which means we're only including transfers and not single leg flights
