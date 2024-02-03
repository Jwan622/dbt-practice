# Notes

Just some notes while looking over the PostgreSQL dump:

- There's a `lock_timeout = 0` line in the postgres dump. Setting lock_timeout to 0 effectively means that transactions won't be timed out due to locks. They will wait indefinitely until the requested lock is acquired. I've been burned by this before in Blue Apron... we actually used long-running transactions when entering the database for development for engineers. This prevented database alter tables from running.
- There is also a `SET statement_timeout = 0;`...meaning there is no statement timeout. The statement timeout is the maximum amount of time a statement (query or command) is allowed to run before it is canceled. When set to 0, as in this case, there is no time limit, and statements will execute until they complete or are manually canceled.

Maybe I'd change this for postgres (presumed to be our OLTP). Some changes:
- In some cases, you might want to set a non-zero lock timeout to prevent transactions from waiting indefinitely for locks, helping to prevent deadlocks.
- Setting a non-zero statement timeout can be useful to prevent long-running queries from causing performance issues or resource contention in the database.


## Notes about the PostgresSQL database, before the tables:
- There's a `bookings` database
- There's a `bookings` schema in the `bookings` database.
- Installs "plpgsql" which is the procedural language extension for PostgreSQL that allows one to write stored procedures and functions.
- `SET search_path = bookings, pg_catalog;:`
This line sets the search path for the current session. The search path determines the order in which schemas are searched when resolving unqualified object names (e.g., table or function names). So, it first looks in the "bookings" schema and then in the "pg_catalog" schema if one references an object without specifying its schema.
- Another helper function:
```sql
CREATE FUNCTION now() RETURNS timestamp with time zone
    LANGUAGE sql IMMUTABLE
    AS $$SELECT '2017-08-15 18:00:00'::TIMESTAMP AT TIME ZONE 'Europe/Moscow';$$;
```
The above function is a SQL function that returns a specific timestamp in the 'Europe/Moscow' time zone.

## Notes about PostgreSQL tables:
- Next, the sql script creates a table named `aircrafts_data` with columns for `aircraft_code`, `model` (in JSONB format), and `range`. There's also a constraint for `range` and it needs to be > 0. It's the maximal flying distance, based on the column comment.
- Defines a view named `aircrafts` that selects data from the `aircrafts_data` table and extracts the aircraft model based on the current setting for `bookings.lang`.
- Creates a table named `airports_data` with columns for `airport_code`, `airport_name` (in JSONB format), `city` (in JSONB format), `coordinates` (point), and `timezone`.
- Similar to `aircrafts` view, the script also defines a view named `airports` that converts data from the airports_data table like `airport_name` and `city` based on the `bookings.lang` file.
- The script finally creates tables for `boarding_passes`, `bookings`, `flights`, `routes`, `seats`, and `tickets`, each with their respective columns and comments.
- The script also defines a default sequence for generating flight IDs.
- 
```postgresql
CREATE SEQUENCE flights_flight_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
```
- The script ends by copying a large amount of data into the `aircrafts_data` and `airports_data` tables.

## Schema

Flights
```postgresql
CREATE TABLE flights (
    flight_id integer NOT NULL,
    flight_no character(6) NOT NULL,
    scheduled_departure timestamp with time zone NOT NULL,
    scheduled_arrival timestamp with time zone NOT NULL,
    departure_airport character(3) NOT NULL,
    arrival_airport character(3) NOT NULL,
    status character varying(20) NOT NULL,
    aircraft_code character(3) NOT NULL,
    actual_departure timestamp with time zone,
    actual_arrival timestamp with time zone,
    CONSTRAINT flights_check CHECK ((scheduled_arrival > scheduled_departure)),
    CONSTRAINT flights_check1 CHECK (((actual_arrival IS NULL) OR ((actual_departure IS NOT NULL) AND (actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure)))),
    CONSTRAINT flights_status_check CHECK (((status)::text = ANY (ARRAY[('On Time'::character varying)::text, ('Delayed'::character varying)::text, ('Departed'::character varying)::text, ('Arrived'::character varying)::text, ('Scheduled'::character varying)::text, ('Cancelled'::character varying)::text])))
);
```

Boarding Passes
```postgresql
CREATE TABLE boarding_passes (
    ticket_no character(13) NOT NULL,
    flight_id integer NOT NULL,
    boarding_no integer NOT NULL,
    seat_no character varying(4) NOT NULL
);
```

Routes
Lol, this view looks fun to understand. We'll notate what it represents here, starting with the CTE f3.
```postgresql
CREATE VIEW routes AS
 WITH f3 AS (
         SELECT f2.flight_no,
            f2.departure_airport,
            f2.arrival_airport,
            f2.aircraft_code,
            f2.duration,
            f2.scheduled_departure,
            f2.scheduled_arrival,
            array_agg(f2.days_of_week) AS days_of_week
           FROM ( SELECT f1.flight_no,
                    f1.departure_airport,
                    f1.arrival_airport,
                    f1.aircraft_code,
                    f1.duration,
                    f1.scheduled_departure,
                    f1.scheduled_arrival,
                    f1.days_of_week
                   FROM ( SELECT flights.flight_no,
                            flights.departure_airport,
                            flights.arrival_airport,
                            flights.aircraft_code,
                            flights.scheduled_arrival::TIME AS scheduled_arrival,
                            flights.scheduled_departure::TIME AS scheduled_departure,
                            (flights.scheduled_arrival - flights.scheduled_departure) AS duration,
                            (to_char(flights.scheduled_departure, 'ID'::text))::integer AS days_of_week
                           FROM flights) f1
                  GROUP BY f1.flight_no, f1.departure_airport, f1.arrival_airport, f1.aircraft_code, f1.duration, f1.days_of_week, f1.scheduled_departure, f1.scheduled_arrival
                  ORDER BY f1.flight_no, f1.departure_airport, f1.arrival_airport, f1.aircraft_code, f1.duration, f1.days_of_week, f1.scheduled_departure, f1.scheduled_arrival) f2
          GROUP BY f2.flight_no, f2.departure_airport, f2.arrival_airport, f2.aircraft_code, f2.duration, f2.scheduled_departure, f2.scheduled_arrival
        )
 SELECT f3.flight_no,
    f3.departure_airport,
    dep.airport_name AS departure_airport_name,
    dep.city AS departure_city,
    f3.arrival_airport,
    arr.airport_name AS arrival_airport_name,
    arr.city AS arrival_city,
    f3.aircraft_code,
    f3.scheduled_departure, 
    f3.scheduled_arrival,
    f3.duration,
    f3.days_of_week
   FROM f3,
    airports dep,
    airports arr
  WHERE ((f3.departure_airport = dep.airport_code) AND (f3.arrival_airport = arr.airport_code));
```

Bookings
```postgresql
CREATE TABLE bookings (
    book_ref character(6) NOT NULL,
    book_date timestamp with time zone NOT NULL,
    total_amount numeric(10,2) NOT NULL
);
```

Seats
```postgresql
CREATE TABLE seats (
    aircraft_code character(3) NOT NULL,
    seat_no character varying(4) NOT NULL,
    fare_conditions character varying(10) NOT NULL,
    CONSTRAINT seats_fare_conditions_check CHECK (((fare_conditions)::text = ANY (ARRAY[('Economy'::character varying)::text, ('Comfort'::character varying)::text, ('Business'::character varying)::text])))
);
```

Tickets
```postgresql
CREATE TABLE tickets (
    ticket_no character(13) NOT NULL,
    book_ref character(6) NOT NULL,
    passenger_id character varying(20) NOT NULL,
    passenger_name text NOT NULL,
    contact_data jsonb
);
```

Airports Data
```postgresql
CREATE TABLE airports_data (
    airport_code character(3) NOT NULL,
    airport_name jsonb NOT NULL,
    city jsonb NOT NULL,
    coordinates point NOT NULL,
    timezone text NOT NULL
);
```

## Views

Routes
```postgresql
CREATE VIEW routes AS
 WITH f3 AS (
         SELECT f2.flight_no,
            f2.departure_airport,
            f2.arrival_airport,
            f2.aircraft_code,
            f2.duration,
            f2.scheduled_departure,
            f2.scheduled_arrival,
            array_agg(f2.days_of_week) AS days_of_week
           FROM ( SELECT f1.flight_no,
                    f1.departure_airport,
                    f1.arrival_airport,
                    f1.aircraft_code,
                    f1.duration,
                    f1.scheduled_departure,
                    f1.scheduled_arrival,
                    f1.days_of_week
                   FROM ( SELECT flights.flight_no,
                            flights.departure_airport,
                            flights.arrival_airport,
                            flights.aircraft_code,
                            flights.scheduled_arrival::TIME AS scheduled_arrival,
                            flights.scheduled_departure::TIME AS scheduled_departure,
                            (flights.scheduled_arrival - flights.scheduled_departure) AS duration,
                            (to_char(flights.scheduled_departure, 'ID'::text))::integer AS days_of_week
                           FROM flights) f1
                  GROUP BY f1.flight_no, f1.departure_airport, f1.arrival_airport, f1.aircraft_code, f1.duration, f1.days_of_week, f1.scheduled_departure, f1.scheduled_arrival
                  ORDER BY f1.flight_no, f1.departure_airport, f1.arrival_airport, f1.aircraft_code, f1.duration, f1.days_of_week, f1.scheduled_departure, f1.scheduled_arrival) f2
          GROUP BY f2.flight_no, f2.departure_airport, f2.arrival_airport, f2.aircraft_code, f2.duration, f2.scheduled_departure, f2.scheduled_arrival
        )
 SELECT f3.flight_no,
    f3.departure_airport,
    dep.airport_name AS departure_airport_name,
    dep.city AS departure_city,
    f3.arrival_airport,
    arr.airport_name AS arrival_airport_name,
    arr.city AS arrival_city,
    f3.aircraft_code,
    f3.scheduled_departure, 
    f3.scheduled_arrival,
    f3.duration,
    f3.days_of_week
   FROM f3,
    airports dep,
    airports arr
  WHERE ((f3.departure_airport = dep.airport_code) AND (f3.arrival_airport = arr.airport_code));
```

Flights
```postgresql
CREATE VIEW flights_v AS
 SELECT f.flight_id,
    f.flight_no,
    f.scheduled_departure,
    timezone(dep.timezone, f.scheduled_departure) AS scheduled_departure_local,
    f.scheduled_arrival,
    timezone(arr.timezone, f.scheduled_arrival) AS scheduled_arrival_local,
    (f.scheduled_arrival - f.scheduled_departure) AS scheduled_duration,
    f.departure_airport,
    dep.airport_name AS departure_airport_name,
    dep.city AS departure_city,
    f.arrival_airport,
    arr.airport_name AS arrival_airport_name,
    arr.city AS arrival_city,
    f.status,
    f.aircraft_code,
    f.actual_departure,
    timezone(dep.timezone, f.actual_departure) AS actual_departure_local,
    f.actual_arrival,
    timezone(arr.timezone, f.actual_arrival) AS actual_arrival_local,
    (f.actual_arrival - f.actual_departure) AS actual_duration
   FROM flights f,
    airports dep,
    airports arr
  WHERE ((f.departure_airport = dep.airport_code) AND (f.arrival_airport = arr.airport_code));
```

Airports
```postgresql
CREATE VIEW airports AS
 SELECT ml.airport_code,
    (ml.airport_name ->> lang()) AS airport_name,
    (ml.city ->> lang()) AS city,
    ml.coordinates,
    ml.timezone
   FROM airports_data ml;
```


Aircrafts
```postgresql
CREATE VIEW aircrafts AS
 SELECT ml.aircraft_code,
    (ml.model ->> lang()) AS model,
    ml.range
   FROM aircrafts_data ml;
```



bookings -> tickets via `book_ref` foreign key
tickets -> boarding_passes via `ticket_no` foreign key
boarding_passes -> flights via `flight_id` foreign key
flights -> airports_data vua `airport_code` foreign key
