WITH max_1_transfer_flights AS (
    SELECT
        route1.flight_no AS first_flight,
        route2.flight_no AS second_flight,
        route1.departure_airport AS first_departure_airport,
        route1.arrival_airport AS first_arrival_airport,
        route2.departure_airport AS second_departure_airport,
        route2.arrival_airport AS second_arrival_airport,
        route1.scheduled_departure as first_scheduled_departure_time,
        route2.scheduled_departure as second_scheduled_departure_time,
        route1.scheduled_arrival as first_scheduled_arrival_time,
        route2.scheduled_arrival as second_scheduled_arrival_time,
        route3.flight_no as third_flight,
        CASE
            WHEN route2.flight_no IS NULL THEN 1
            ELSE 0
        END AS is_transfer
    FROM routes AS route1
    LEFT OUTER JOIN routes AS route2
    ON route1.arrival_airport = route2.departure_airport
    LEFT OUTER JOIN routes AS route3
    ON route2.arrival_airport = route3.departure_airport
    AND route3.flight_no IS NULL
),
max_1_transfer_and_non_circular_flights AS (
  SELECT
    first_flight,
    second_flight,
    first_departure_airport,
    first_arrival_airport,
    second_departure_airport,
    second_arrival_airport,
    first_scheduled_departure_time,
    second_scheduled_departure_time,
    first_scheduled_arrival_time,
    second_scheduled_arrival_time,
    is_transfer
  FROM max_1_transfer_flights
  WHERE first_departure_airport <> second_arrival_airport -- non-circular
),
max_1_transfer_and_non_circular_flights_within_24h AS (
    SELECT *
    FROM max_1_transfer_and_non_circular_flights
    WHERE second_scheduled_arrival_time - first_scheduled_departure_time <= interval '24 hours'
)
SELECT
    first_flight as first_flight_no,
    second_flight as second_flight_no,
    first_departure_airport as origin_airport,
    first_scheduled_departure_time as first_scheduled_departure_time,
    COALESCE(second_arrival_airport, first_arrival_airport) as destination_airport_code,
    COALESCE(second_scheduled_arrival_time, first_scheduled_arrival_time) as destination_arrival_time,
    CASE WHEN second_flight IS NOT NULL THEN first_arrival_airport END as transfer_airport_code,
    CASE WHEN second_flight IS NOT NULL THEN first_scheduled_arrival_time END as transfer_airport_arrival_time,
    CASE WHEN second_flight IS NOT NULL THEN second_scheduled_departure_time END as transfer_airport_departure_time
FROM max_1_transfer_and_non_circular_flights_within_24h AS valid_routes