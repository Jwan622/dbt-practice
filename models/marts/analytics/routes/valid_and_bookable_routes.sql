{{
    config(
        materialized='table',
    )
}}

WITH no_transfer_flights AS (
    SELECT
        route1.flight_no AS first_flight,
        NULL AS second_flight,
        route1.departure_airport AS first_departure_airport,
        route1.arrival_airport AS first_arrival_airport,
        NULL AS second_departure_airport,
        NULL AS second_arrival_airport,
        route1.scheduled_departure as first_scheduled_departure_time,
        NULL::time without time zone as second_scheduled_departure_time,
        route1.scheduled_arrival as first_scheduled_arrival_time,
        NULL::time without time zone as second_scheduled_arrival_time,
        route1.duration as first_duration,
        NULL::INTERVAL as second_duration,
        route1.days_of_week as first_days_of_week,
        NULL::INTEGER[] as second_days_of_week
    FROM routes AS route1
),
one_transfer_flights AS (
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
        route1.duration as first_duration,
        route2.duration as second_duration,
        route1.days_of_week as first_days_of_week,
        route2.days_of_week as second_days_of_week
    FROM routes AS route1
    INNER JOIN routes AS route2
    ON route1.arrival_airport = route2.departure_airport
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
    first_duration,
    second_duration,
    first_days_of_week,
    second_days_of_week
  FROM one_transfer_flights
  WHERE first_departure_airport <> second_arrival_airport -- non-circular
  UNION ALL
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
    first_duration,
    second_duration,
    first_days_of_week,
    second_days_of_week
  FROM no_transfer_flights
),
max_1_transfer_and_non_circular_flights_with_travel_times AS ( -- god this sucked. I hate time
    SELECT
        first_flight,
        second_flight,
        first_departure_airport,
        first_arrival_airport,
        second_departure_airport,
        second_arrival_airport,
        first_scheduled_departure_time,
        first_scheduled_arrival_time,
        second_scheduled_departure_time,
        second_scheduled_arrival_time,
        first_days_of_week,
        second_days_of_week,
        CASE WHEN first_scheduled_arrival_time - first_scheduled_departure_time < '00:00:00'::INTERVAL OR second_scheduled_departure_time - first_scheduled_arrival_time < '00:00:00'::INTERVAL
            THEN 1 ELSE 0
        END as is_first_flight_crossover_to_next_day,
        first_duration,
        CASE WHEN second_scheduled_departure_time - first_scheduled_arrival_time < '00:00:00'::INTERVAL
            THEN second_scheduled_departure_time - first_scheduled_arrival_time + INTERVAL '24 HOURS'
            ELSE second_scheduled_departure_time - first_scheduled_arrival_time
        END as layover_duration,
        second_duration
    FROM max_1_transfer_and_non_circular_flights
), max_1_transfer_and_non_circular_flights_within_24hours AS (
    SELECT
        first_flight,
        second_flight,
        first_departure_airport,
        first_arrival_airport,
        second_departure_airport,
        second_arrival_airport,
        first_scheduled_departure_time,
        first_scheduled_arrival_time,
        second_scheduled_departure_time,
        second_scheduled_arrival_time,
        first_days_of_week,
        second_days_of_week,
        CASE
          WHEN is_first_flight_crossover_to_next_day = 1
          THEN
            ARRAY(
              SELECT
                CASE
                  WHEN day = 7 THEN 1 -- when we add 7 + 1... the day actually becomes 1
                  ELSE day + 1
                END
              FROM unnest(first_days_of_week) AS day
            )
        END AS first_days_of_week_adjusted_because_overnight,
        COALESCE(first_duration, '00:00:00'::INTERVAL) + COALESCE(layover_duration, '00:00:00'::INTERVAL) + COALESCE(second_duration, '00:00:00'::INTERVAL) as total_travel_time
    FROM max_1_transfer_and_non_circular_flights_with_travel_times
    WHERE first_duration + layover_duration + second_duration <= INTERVAL '24 HOURS'
    OR second_flight is null -- I think we still want all of the single leg flights too since they're valid by the README rules
), max_1_transfer_and_non_circular_flights_within_24hours_with_adjusted_days_of_week AS (
    SELECT
        first_flight,
        second_flight,
        first_departure_airport,
        first_arrival_airport,
        second_departure_airport,
        second_arrival_airport,
        first_scheduled_departure_time,
        first_scheduled_arrival_time,
        second_scheduled_departure_time,
        second_scheduled_arrival_time,
        first_days_of_week,
        second_days_of_week,
        CASE
            WHEN second_flight IS NULL THEN first_days_of_week
            WHEN first_days_of_week_adjusted_because_overnight IS NOT NULL and second_flight IS NOT NULL THEN
                ARRAY(
                  SELECT DISTINCT ON (elem) elem
                  FROM unnest(first_days_of_week_adjusted_because_overnight::integer[]) elem
                  WHERE elem IN (SELECT unnest(second_days_of_week::integer[]))
                  ORDER BY elem
                )
            ELSE
                ARRAY(
                  SELECT DISTINCT ON (elem) elem
                  FROM unnest(first_days_of_week::integer[]) elem
                  WHERE elem IN (SELECT unnest(second_days_of_week::integer[]))
                  ORDER BY elem
                )
        END AS days_of_week,
        total_travel_time
    FROM max_1_transfer_and_non_circular_flights_within_24hours AS valid_routes
) SELECT
    first_flight as first_flight_no,
    second_flight as second_flight_no,
    first_departure_airport as origin_airport_code,
    COALESCE(second_arrival_airport, first_arrival_airport) as destination_airport_code,
    CASE WHEN second_flight IS NOT NULL THEN first_arrival_airport END as transfer_airport_code,
    first_scheduled_departure_time as first_scheduled_departure_time,
    CASE WHEN second_flight IS NOT NULL THEN first_scheduled_arrival_time END as transfer_airport_arrival_time,
    CASE WHEN second_flight IS NOT NULL THEN second_scheduled_departure_time END as transfer_airport_departure_time,
    COALESCE(second_scheduled_arrival_time, first_scheduled_arrival_time) as destination_arrival_time,
    days_of_week,
    total_travel_time
FROM max_1_transfer_and_non_circular_flights_within_24hours_with_adjusted_days_of_week AS valid_routes
WHERE array_length(days_of_week, 1) IS NOT NULL
