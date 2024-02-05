with expected_row as (
  select *
  FROM {{ ref('valid_and_bookable_routes') }}
  WHERE
    first_flight_no = 'PG0370' AND
    second_flight_no = 'PG0367' AND
    origin_airport_code = 'DME' AND
    destination_airport_code = 'EYK' AND
    transfer_airport_code = 'KRO' AND
    first_scheduled_departure_time = '08:50:00'::time AND
    transfer_airport_arrival_time = '11:15:00'::time AND
    transfer_airport_departure_time = '04:25:00'::time AND
    destination_arrival_time = '07:25:00'::time AND
    days_of_week = '{1}'::integer[] AND
    total_travel_time = '22:35:00'::interval
)
select 'the row is not found' as message
where NOT EXISTS (select * from expected_row)
