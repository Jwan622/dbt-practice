# Notes I kept while developing the models

These are notes I took for myself while writing the models. Also, I left some questions I need to answer for myself that came up over the course of development of the dbt models

## Ticket Sales models
- What's the diff between extract and date_trunc functions for getting the day. Which do I want and why.

### Results for Ticket Sales Query

It seemed odd to me that the daily total tickets increased over time which made me believe I was accidentally aggregating instead of just counting tickets day by day... but it seems to checkout when I run simple where queries. Below are the results for day 2 and 3:

```postgresql
bookings=# select * from bookings where DATE_TRUNC('day',book_date) = '2017-04-22'
;
-[ RECORD 1 ]+-----------------------
book_ref     | 0D7742
book_date    | 2017-04-22 18:55:00+00
total_amount | 120600.00
-[ RECORD 2 ]+-----------------------
book_ref     | 41A916
book_date    | 2017-04-22 11:45:00+00
total_amount | 19600.00
-[ RECORD 3 ]+-----------------------
book_ref     | AAD5A0
book_date    | 2017-04-22 22:21:00+00
total_amount | 23200.00
-[ RECORD 4 ]+-----------------------
book_ref     | D0E1DA
book_date    | 2017-04-22 06:01:00+00
total_amount | 63300.00

bookings=# select * from bookings where DATE_TRUNC('day',book_date) = '2017-04-23'
;
-[ RECORD 1 ]+-----------------------
book_ref     | 168C11
book_date    | 2017-04-23 23:25:00+00
total_amount | 31800.00
-[ RECORD 2 ]+-----------------------
book_ref     | 1C1D18
book_date    | 2017-04-23 02:13:00+00
total_amount | 24800.00
-[ RECORD 3 ]+-----------------------
book_ref     | 2711BF
book_date    | 2017-04-23 00:09:00+00
total_amount | 59300.00
-[ RECORD 4 ]+-----------------------
book_ref     | 2C09A1
book_date    | 2017-04-23 10:12:00+00
total_amount | 28400.00
-[ RECORD 5 ]+-----------------------
book_ref     | 4BA14C
book_date    | 2017-04-23 09:48:00+00
total_amount | 31600.00
-[ RECORD 6 ]+-----------------------
book_ref     | BAE0C8
book_date    | 2017-04-23 23:23:00+00
total_amount | 81700.00
-[ RECORD 7 ]+-----------------------
book_ref     | DCEF58
book_date    | 2017-04-23 13:47:00+00
total_amount | 56900.00
-[ RECORD 8 ]+-----------------------
book_ref     | F9909D
book_date    | 2017-04-23 04:29:00+00
total_amount | 40300.00
-[ RECORD 9 ]+-----------------------
book_ref     | FF1CEF
book_date    | 2017-04-23 01:56:00+00
total_amount | 26800.00
```

So I think the results from my model make sense:

```postgresql
-[ RECORD 1 ]---------+-----------------------
date                  | 2017-04-21 00:00:00+00
daily_total_tickets   | 1
rolling_7_days_total  | 1
rolling_28_days_total | 1
-[ RECORD 2 ]---------+-----------------------
date                  | 2017-04-22 00:00:00+00
daily_total_tickets   | 5
rolling_7_days_total  | 6
rolling_28_days_total | 6
-[ RECORD 3 ]---------+-----------------------
date                  | 2017-04-23 00:00:00+00
daily_total_tickets   | 14
rolling_7_days_total  | 20
rolling_28_days_total | 20
-[ RECORD 4 ]---------+-----------------------
date                  | 2017-04-24 00:00:00+00
daily_total_tickets   | 42
rolling_7_days_total  | 62
rolling_28_days_total | 62
-[ RECORD 5 ]---------+-----------------------
date                  | 2017-04-25 00:00:00+00
daily_total_tickets   | 114
rolling_7_days_total  | 176
rolling_28_days_total | 176
-[ RECORD 6 ]---------+-----------------------
date                  | 2017-04-26 00:00:00+00
daily_total_tickets   | 293
rolling_7_days_total  | 469
rolling_28_days_total | 469
-[ RECORD 7 ]---------+-----------------------
date                  | 2017-04-27 00:00:00+00
daily_total_tickets   | 537
rolling_7_days_total  | 1006
rolling_28_days_total | 1006
-[ RECORD 8 ]---------+-----------------------
date                  | 2017-04-28 00:00:00+00
daily_total_tickets   | 1089
rolling_7_days_total  | 2094
rolling_28_days_total | 2095
-[ RECORD 9 ]---------+-----------------------
date                  | 2017-04-29 00:00:00+00
daily_total_tickets   | 1899
rolling_7_days_total  | 3988
rolling_28_days_total | 3994
```

**Quick eyeball check**: Eyeballing and doing the math by hand at day 2, day 7, and day 8 makes me confident that this query is correct.


## Redemptions
When I enter the container and connect to the postgres instance (notes in the docs folder on how to do this), and run:
```postgresql
 select distinct cost from bookings order by cost asc
```

I see this:

| total_amount | 
|--------------| 
| -12345678.00 |
| -1.00        |
| 0.00         |
| 3400.00      |
| 3700.00      |
| ... |

so it seems like different airlines have different ways of implying redemptions. The first 3 look like dummy values an airline uses to signify a redemption.


**Question for myself**:
1. But wait, do those `total_amounts` correspond to different airlines? If all 3 of the weird numbers (-12345678.00, -1.00, 0.00) correspond to different airlines then I'm confident that's how each airline handles free redemptions. But what if -1.00 and 0.00 are from the same airline? Then they probably mean something different and one of those numbers isn't associated with a redemption. But oddly... I can't seem to find airline in the data! 

So our schema again:
```
bookings -> tickets via `book_ref` foreign key
tickets -> boarding_passes via `ticket_no` foreign key
boarding_passes -> flights via `flight_id` foreign key
flights -> airports_data vua `airport_code` foreign key
```

So given our schema, let's run:

```
select DISTINCT ON (total_amount) total_amount, *
from bookings as b
INNER JOIN tickets as t
ON t.book_ref = b.book_ref
INNER JOIN boarding_passes as bp
ON bp.ticket_no = t.ticket_no
INNER JOIN flights as f
ON bp.flight_id = f.flight_id
INNER JOIN aircrafts_data as ac
ON ac.aircraft_code = f.aircraft_code
WHERE total_amount = 0 or total_amount = -1 or total_amount = -12345678.00
limit 5;
```
The results in expanded mode (type `\x` to see output):

```
-[ RECORD 1 ]-------+------------------------------------------------------------------------
total_amount        | -12345678.00
book_ref            | 00F7B1
book_date           | 2017-06-29 11:04:00+00
total_amount        | -12345678.00
ticket_no           | 0005434458539
book_ref            | 00F7B1
passenger_id        | 0444 821040
passenger_name      | MARIYA KUZNECOVA
contact_data        | {"phone": "+70019954247"}
ticket_no           | 0005434458539
flight_id           | 14571
boarding_no         | 32
seat_no             | 5C
flight_id           | 14571
flight_no           | PG0241
scheduled_departure | 2017-07-20 06:40:00+00
scheduled_arrival   | 2017-07-20 07:30:00+00
departure_airport   | SVO
arrival_airport     | CSY
status              | Arrived
aircraft_code       | SU9
actual_departure    | 2017-07-20 06:43:00+00
actual_arrival      | 2017-07-20 07:33:00+00
aircraft_code       | SU9
model               | {"en": "Sukhoi Superjet-100", "ru": "Сухой Суперджет-100"}
range               | 3000
-[ RECORD 2 ]-------+------------------------------------------------------------------------
total_amount        | -1.00
book_ref            | 00FC04
book_date           | 2017-05-14 21:31:00+00
total_amount        | -1.00
ticket_no           | 0005433931255
book_ref            | 00FC04
passenger_id        | 8649 813759
passenger_name      | NIKITA IVANOV
contact_data        | {"email": "ivanovnikita041966@postgrespro.ru", "phone": "+70023329964"}
ticket_no           | 0005433931255
flight_id           | 2986
boarding_no         | 47
seat_no             | 15E
flight_id           | 2986
flight_no           | PG0210
scheduled_departure | 2017-06-09 15:00:00+00
scheduled_arrival   | 2017-06-09 16:50:00+00
departure_airport   | DME
arrival_airport     | MRV
status              | Arrived
aircraft_code       | 733
actual_departure    | 2017-06-09 15:02:00+00
actual_arrival      | 2017-06-09 16:51:00+00
aircraft_code       | 733
model               | {"en": "Boeing 737-300", "ru": "Боинг 737-300"}
range               | 4200
-[ RECORD 3 ]-------+------------------------------------------------------------------------
total_amount        | 0.00
book_ref            | 00C3E6
book_date           | 2017-06-11 04:59:00+00
total_amount        | 0.00
ticket_no           | 0005432140137
book_ref            | 00C3E6
passenger_id        | 4265 931290
passenger_name      | LYUBOV FILIPPOVA
contact_data        | {"email": "filippova-l_1965@postgrespro.ru", "phone": "+70955130158"}
ticket_no           | 0005432140137
flight_id           | 10949
boarding_no         | 48
seat_no             | 14A
flight_id           | 10949
flight_no           | PG0529
scheduled_departure | 2017-06-27 06:50:00+00
scheduled_arrival   | 2017-06-27 08:20:00+00
departure_airport   | SVO
arrival_airport     | UFA
status              | Arrived
aircraft_code       | 763
actual_departure    | 2017-06-27 06:51:00+00
actual_arrival      | 2017-06-27 08:20:00+00
aircraft_code       | 763
model               | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}
range               | 7900
(END)
```

**Quick eyeball check**: By eyeballing this data, it seems like nothing in common and so I assume those 3 `total_amounts` are from different airlines meaning the odd numbers (0, -1, and -12345678.00) are indeed redemptions. So we can write this as our query to find redemptions:

```postgresql
    SELECT
        DATE_TRUNC('day', b.book_date) AS date,
        COUNT(*) AS redemption_count
    FROM bookings b
    WHERE total_amount = -1 
        OR total_amount = 0 
        OR total_amount = -12345678.00
    GROUP BY date
    ORDER BY redemption_count desc
```


## Valid and bookable routes

Harder problem here....mainly because I was unclear what the question was asking. But by inspecting the data, I think I figured out what it meant!

### The routes view
Before we tackle the data...let's try to understand the routes view query a bit better in the postgres dump file.

This is `f2`, a subquery.
```postgresql
SELECT f1.flight_no,
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
ORDER BY f1.flight_no, f1.departure_airport, f1.arrival_airport, f1.aircraft_code, f1.duration, f1.days_of_week, f1.scheduled_departure, f1.scheduled_arrival
```

The results look like this:

```postgresql
flight_no | departure_airport | arrival_airport | aircraft_code | duration | scheduled_departure | scheduled_arrival | days_of_week
-----------+-------------------+-----------------+---------------+----------+---------------------+-------------------+--------------
 PG0001    | UIK               | SGC             | CR2           | 02:20:00 | 12:15:00            | 14:35:00          |            6
 PG0002    | SGC               | UIK             | CR2           | 02:20:00 | 07:10:00            | 09:30:00          |            7
 PG0003    | IWA               | AER             | CR2           | 02:10:00 | 06:50:00            | 09:00:00          |            2
 PG0003    | IWA               | AER             | CR2           | 02:10:00 | 06:50:00            | 09:00:00          |            6
 PG0004    | AER               | IWA             | CR2           | 02:10:00 | 09:45:00            | 11:55:00          |            3
 PG0004    | AER               | IWA             | CR2           | 02:10:00 | 09:45:00            | 11:55:00          |            7
 PG0005    | DME               | PKV             | CN1           | 02:05:00 | 12:40:00            | 14:45:00          |            2
 PG0005    | DME               | PKV             | CN1           | 02:05:00 | 12:40:00            | 14:45:00          |            5
 PG0005    | DME               | PKV             | CN1           | 02:05:00 | 12:40:00            | 14:45:00          |            7
 PG0006    | PKV               | DME             | CN1           | 02:05:00 | 14:20:00            | 16:25:00          |            1
```

And then finally f3 `array_aggs` the days of the week together. Notice it does not `GROUP BY` the days of the week column so that `array_agg` function can aggregate the days of the week the routes fly.

https://www.postgresqltutorial.com/postgresql-aggregate-functions/postgresql-array_agg/

This is f3:
```postgresql
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
```

the view is hydrated with airport data like airport_name and the city of the airport using the `airport_code` to join.


Okay so let's inspect the routes data bit.

- How many routes are there?
```postgresql
select count(1) from routes;
 count
-------
   710
(1 row)
```

### Questions
Quite a few questions and slight gotchas came up on this. I'll tackle one at a time.

- What does max one transfer mean?
- Do some routes start and end at the same airport?

____
First the issue of **max** one transfer. My approach was to join on routes twice so we can check if the 2nd transfer is NULL. I did something like this:

```postgresql
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
            WHEN route2.flight_no IS NOT NULL THEN 1
            ELSE 0
        END AS is_transfer
    FROM routes AS route1
    LEFT OUTER JOIN routes AS route2
    ON route1.arrival_airport = route2.departure_airport
    LEFT OUTER JOIN routes AS route3
    ON route2.arrival_airport = route3.departure_airport
    WHERE route3.flight_no IS NULL
```

results:

```
(0 rows)
```

Are there any orphan airports?

```
SELECT DISTINCT departure_airport
FROM routes
WHERE departure_airport NOT IN (SELECT DISTINCT arrival_airport FROM routes)
;
 departure_airport
-------------------
(0 rows)
```

So there are no departure airports that are not arrival airports in the routes view. Dammit.

Okay so I think I understood the question wrong. The "max" part of that question just means limit your universe of potential routes to just 1 transfer routes or 0 transfer routes even though there are definitely transfer routes with 2 or 3 hops. You can actually have infinite transfers. There are no orphan destinations.

I created a test schema named `jwan` and some dummy tables in the schema to play around with so I can be more sure of my queries.
my test table:
```
 flight_no | departure_airport |      departure_airport_name      | departure_city | arrival_airport |       arrival_airport_name       | arrival_city | aircraft_code | scheduled_departure | scheduled_arrival | duration |  days_of_week
-----------+-------------------+----------------------------------+----------------+-----------------+----------------------------------+--------------+---------------+---------------------+-------------------+----------+-----------------
 PG0001    | UIK               | Ust-Ilimsk Airport               | Ust Ilimsk     | SGC             | Surgut Airport                   | Surgut       | CR2           | 12:15:00            | 14:35:00          | 02:20:00 | {6}
 PG0002    | SGC               | Surgut Airport                   | Surgut         | UIK             | Ust-Ilimsk Airport               | Ust Ilimsk   | CR2           | 07:10:00            | 09:30:00          | 02:20:00 | {7}
 PG0003    | IWA               | Ivanovo South Airport            | Ivanovo        | AER             | Sochi International Airport      | Sochi        | CR2           | 06:50:00            | 09:00:00          | 02:10:00 | {2,6}
 PG0004    | AER               | Sochi International Airport      | Sochi          | IWA             | Ivanovo South Airport            | Ivanovo      | CR2           | 09:45:00            | 11:55:00          | 02:10:00 | {3,7}
 PG0005    | DME               | Domodedovo International Airport | Moscow         | PKV             | Pskov Airport                    | Pskov        | CN1           | 12:40:00            | 14:45:00          | 02:05:00 | {2,5,7}
 PG0006    | PKV               | Pskov Airport                    | Pskov          | DME             | Domodedovo International Airport | Moscow       | CN1           | 14:20:00            | 16:25:00          | 02:05:00 | {1,4,6}
 PG0007    | VKO               | Vnukovo International Airport    | Moscow         | JOK             | Yoshkar-Ola Airport              | Yoshkar-Ola  | CN1           | 09:40:00            | 11:50:00          | 02:10:00 | {1,2,3,4,5,6,7}
 PG0008    | VKO               | Vnukovo International Airport    | Moscow         | JOK             | Yoshkar-Ola Airport              | Yoshkar-Ola  | CN1           | 08:45:00            | 10:55:00          | 02:10:00 | {1,2,3,4,5,6,7}
 PG0009    | JOK               | Yoshkar-Ola Airport              | Yoshkar-Ola    | VKO             | Vnukovo International Airport    | Moscow       | CN1           | 09:10:00            | 11:20:00          | 02:10:00 | {1,2,3,4,5,6,7}
 PG0010    | JOK               | Yoshkar-Ola Airport              | Yoshkar-Ola    | VKO             | Vnukovo International Airport    | Moscow       | CN1           | 09:25:00            | 11:35:00          | 02:10:00 | {1,2,3,4,5,6,7}
(10 rows)

(END)
```

It has just 10 rows. **But the thing to note here is that PG0007 and PG0008 share the same departure airport (VOK) and arrival airport (JOK) but the scheduled_departure and scheduled_arrival are different.** Those are 2 different routes... or least that's the assumption I'm making. Same goes for PG0009 and PG0010. 

But I think these should go away when we account for circular routes.

For 1 transfer routes:
```
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
        route2.scheduled_arrival as second_scheduled_arrival_time
    FROM jwan.test_routes AS route1
    LEFT OUTER JOIN jwan.test_routes AS route2
    ON route1.arrival_airport = route2.departure_airport
;
```

which returned me this:

```
first_flight | second_flight | first_departure_airport | first_arrival_airport | second_departure_airport | second_arrival_airport | first_scheduled_departure_time | second_scheduled_departure_time | first_scheduled_arrival_time | second_scheduled_arrival_time
--------------+---------------+-------------------------+-----------------------+--------------------------+------------------------+--------------------------------+---------------------------------+------------------------------+-------------------------------
 PG0001       | PG0002        | UIK                     | SGC                   | SGC                      | UIK                    | 12:15:00                       | 07:10:00                        | 14:35:00                     | 09:30:00
 PG0002       | PG0001        | SGC                     | UIK                   | UIK                      | SGC                    | 07:10:00                       | 12:15:00                        | 09:30:00                     | 14:35:00
 PG0003       | PG0004        | IWA                     | AER                   | AER                      | IWA                    | 06:50:00                       | 09:45:00                        | 09:00:00                     | 11:55:00
 PG0004       | PG0003        | AER                     | IWA                   | IWA                      | AER                    | 09:45:00                       | 06:50:00                        | 11:55:00                     | 09:00:00
 PG0005       | PG0006        | DME                     | PKV                   | PKV                      | DME                    | 12:40:00                       | 14:20:00                        | 14:45:00                     | 16:25:00
 PG0006       | PG0005        | PKV                     | DME                   | DME                      | PKV                    | 14:20:00                       | 12:40:00                        | 16:25:00                     | 14:45:00
 PG0007       | PG0010        | VKO                     | JOK                   | JOK                      | VKO                    | 09:40:00                       | 09:25:00                        | 11:50:00                     | 11:35:00
 PG0007       | PG0009        | VKO                     | JOK                   | JOK                      | VKO                    | 09:40:00                       | 09:10:00                        | 11:50:00                     | 11:20:00
 PG0008       | PG0010        | VKO                     | JOK                   | JOK                      | VKO                    | 08:45:00                       | 09:25:00                        | 10:55:00                     | 11:35:00
 PG0008       | PG0009        | VKO                     | JOK                   | JOK                      | VKO                    | 08:45:00                       | 09:10:00                        | 10:55:00                     | 11:20:00
 PG0009       | PG0008        | JOK                     | VKO                   | VKO                      | JOK                    | 09:10:00                       | 08:45:00                        | 11:20:00                     | 10:55:00
 PG0009       | PG0007        | JOK                     | VKO                   | VKO                      | JOK                    | 09:10:00                       | 09:40:00                        | 11:20:00                     | 11:50:00
 PG0010       | PG0008        | JOK                     | VKO                   | VKO                      | JOK                    | 09:25:00                       | 08:45:00                        | 11:35:00                     | 10:55:00
 PG0010       | PG0007        | JOK                     | VKO                   | VKO                      | JOK                    | 09:25:00                       | 09:40:00                        | 11:35:00                     | 11:50:00
(14 rows)

(END)
```

____
So I know the `README.md` says "A bookable route cannot start and end at the same airport." but does this mean routes with a transfer or for a single leg? Do single leg routes that start and end in a single airport even exist? Do routes with a transfer that start and end at the same airport count as a valid because they stopped somewhere else in the middle? Let's check:

So the below is a query for single-leg (non-transfer) routes that start and end at the same place.

```
select count(1) from routes where arrival_airport = departure_airport;
```

result:

```
count
-------
     0
(1 row)
```
Since there are none, I think that requirement actually refers to routes with a transfer that start and end at the same airport. I think that's not a valid route. Let's see how many of those exist. But why is that not a valid route? Who knows... maybe that's just to ensure people don't fly somewhere and come right back home the same day. But isn't that a round-trip ticket? Isn't that route valid? Oh well....nvm. I wish I could eliminate same day rount trips but the timestamps are just `time` without a date!

In order to see if I'm doing this correctly, let's create some data:

```
select * from routes where departure_airport = 'GDZ';

flight_no | departure_airport | departure_airport_name | departure_city | arrival_airport |        arrival_airport_name        | arrival_city | aircraft_code | scheduled_departure | scheduled_arrival | duration | days_of_week
-----------+-------------------+------------------------+----------------+-----------------+------------------------------------+--------------+---------------+---------------------+-------------------+----------+--------------
 PG0012    | GDZ               | Gelendzhik Airport     | Gelendzhik     | VKO             | Vnukovo International Airport      | Moscow       | CR2           | 07:55:00            | 09:40:00          | 01:45:00 | {2,4,6}
 PG0034    | GDZ               | Gelendzhik Airport     | Gelendzhik     | ESL             | Elista Airport                     | Elista       | CN1           | 08:25:00            | 10:10:00          | 01:45:00 | {3,7}
 PG0250    | GDZ               | Gelendzhik Airport     | Gelendzhik     | DME             | Domodedovo International Airport   | Moscow       | CR2           | 10:10:00            | 11:55:00          | 01:45:00 | {2,4,6}
 PG0262    | GDZ               | Gelendzhik Airport     | Gelendzhik     | SVO             | Sheremetyevo International Airport | Moscow       | CR2           | 08:20:00            | 10:10:00          | 01:50:00 | {2,4,6}
 PG0528    | GDZ               | Gelendzhik Airport     | Gelendzhik     | ROV             | Rostov-on-Don Airport              | Rostov       | CN1           | 12:50:00            | 13:55:00          | 01:05:00 | {3,6}
(5 rows)
(END)
```

I'm going to see if my logic does NOT include the GDZ -> VKO -> GDZ route.

```bash
insert into jwan.test_routes select * from routes where departure_airport = 'GDZ' limit 2;
```

let's also enter in the `departure_airport = 'VKO` data so that eventually, the GDZ -> VKO -> GDZ route is eliminated.

```bash
insert into jwan.test_routes select * from routes where departure_airport = 'VKO' and arrival_airport = 'GDZ' limit 1;
```

and insert one more departure_airport = 'GDZ' row and a non-circular and circular departure_airport = 'ESL' route and we get:
```
insert into jwan.test_routes select * from routes where departure_airport = 'ESL' and arrival_airport = 'GDZ' limit 1;
insert into jwan.test_routes select * from routes where departure_airport = 'VKO' and arrival_airport = 'JOK' limit 1;
```

```
 flight_no | departure_airport |    departure_airport_name     | departure_city | arrival_airport |        arrival_airport_name        | arrival_city | aircraft_code | scheduled_departure | scheduled_arrival | duration |  days_of_week
-----------+-------------------+-------------------------------+----------------+-----------------+------------------------------------+--------------+---------------+---------------------+-------------------+----------+-----------------
 PG0300    | ESL               | Elista Airport                | Elista         | SVO             | Sheremetyevo International Airport | Moscow       | CN1           | 08:20:00            | 12:10:00          | 03:50:00 | {1,2,3,4,5,6,7}
 PG0033    | ESL               | Elista Airport                | Elista         | GDZ             | Gelendzhik Airport                 | Gelendzhik   | CN1           | 13:50:00            | 15:35:00          | 01:45:00 | {2,6}
 PG0007    | VKO               | Vnukovo International Airport | Moscow         | JOK             | Yoshkar-Ola Airport                | Yoshkar-Ola  | CN1           | 09:40:00            | 11:50:00          | 02:10:00 | {1,2,3,4,5,6,7}
 PG0012    | GDZ               | Gelendzhik Airport            | Gelendzhik     | VKO             | Vnukovo International Airport      | Moscow       | CR2           | 07:55:00            | 09:40:00          | 01:45:00 | {2,4,6}
 PG0034    | GDZ               | Gelendzhik Airport            | Gelendzhik     | ESL             | Elista Airport                     | Elista       | CN1           | 08:25:00            | 10:10:00          | 01:45:00 | {3,7}
 PG0049    | VKO               | Vnukovo International Airport | Moscow         | GDZ             | Gelendzhik Airport                 | Gelendzhik   | CR2           | 10:05:00            | 11:50:00          | 01:45:00 | {2,5,7}
(6 rows)
(END)
(7 rows)
```

When we run our query we get this which looks right:

```
bookings=# WITH no_transfer_flights AS (
    SELECT
 first_flight | second_flight | first_departure_airport | first_arrival_airport | second_departure_airport | second_arrival_airport | first_scheduled_departure_time | second_scheduled_departure_time | first_scheduled_arrival_time | second_scheduled_arrival_time
--------------+---------------+-------------------------+-----------------------+--------------------------+------------------------+--------------------------------+---------------------------------+------------------------------+-------------------------------
 PG0034       | PG0300        | GDZ                     | ESL                   | ESL                      | SVO                    | 08:25:00                       | 08:20:00                        | 10:10:00                     | 12:10:00
 PG0012       | PG0007        | GDZ                     | VKO                   | VKO                      | JOK                    | 07:55:00                       | 09:40:00                        | 09:40:00                     | 11:50:00
 PG0033       | PG0012        | ESL                     | GDZ                   | GDZ                      | VKO                    | 13:50:00                       | 07:55:00                        | 15:35:00                     | 09:40:00
 PG0049       | PG0034        | VKO                     | GDZ                   | GDZ                      | ESL                    | 10:05:00                       | 08:25:00                        | 11:50:00                     | 10:10:00
 PG0300       |               | ESL                     | SVO                   |                          |                        | 08:20:00                       |                                 | 12:10:00                     |
 PG0033       |               | ESL                     | GDZ                   |                          |                        | 13:50:00                       |                                 | 15:35:00                     |
 PG0007       |               | VKO                     | JOK                   |                          |                        | 09:40:00                       |                                 | 11:50:00                     |
 PG0012       |               | GDZ                     | VKO                   |                          |                        | 07:55:00                       |                                 | 09:40:00                     |
 PG0034       |               | GDZ                     | ESL                   |                          |                        | 08:25:00                       |                                 | 10:10:00                     |
 PG0049       |               | VKO                     | GDZ                   |                          |                        | 10:05:00                       |                                 | 11:50:00                     |
(10 rows)

(END)
```

Main point of this QA: We'd expect the GDZ -> VKO -> GDZ route to **not** be included and we expect the GDZ -> ESL -> GDZ route to *not* be included but we'd expect to see the GDZ -> ESL -> SVO route.

### Our final test sql code against our schema

```
WITH no_transfer_flights AS (
    SELECT
        route1.flight_no AS first_flight,
        NULL AS second_flight,
        route1.departure_airport AS first_departure_airport,
        route1.arrival_airport AS first_arrival_airport,
        NULL AS second_departure_airport,
        NULL AS second_arrival_airport,
        route1.scheduled_departure as first_scheduled_departure_time,
        route1.scheduled_arrival as first_scheduled_arrival_time,
        NULL::time without time zone as second_scheduled_departure_time,
        NULL::time without time zone as second_scheduled_arrival_time
    FROM jwan.test_routes AS route1
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
        route1.scheduled_arrival as first_scheduled_arrival_time,
        route2.scheduled_departure as second_scheduled_departure_time,
        route2.scheduled_arrival as second_scheduled_arrival_time
    FROM jwan.test_routes AS route1
    LEFT OUTER JOIN jwan.test_routes AS route2
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
    first_scheduled_arrival_time,
    second_scheduled_departure_time,
    second_scheduled_arrival_time
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
    first_scheduled_arrival_time,
    second_scheduled_departure_time,
    second_scheduled_arrival_time
  FROM no_transfer_flights
),
max_1_transfer_and_non_circular_flights_with_travel_times AS (
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
        CASE WHEN first_scheduled_arrival_time - first_scheduled_departure_time < '00:00:00'::INTERVAL
            THEN first_scheduled_arrival_time - first_scheduled_departure_time + INTERVAL '24 HOURS' 
            ELSE first_scheduled_arrival_time - first_scheduled_departure_time 
        END as normalized_first_leg,
        CASE WHEN second_scheduled_departure_time - first_scheduled_arrival_time < '00:00:00'::INTERVAL
            THEN second_scheduled_departure_time - first_scheduled_arrival_time + INTERVAL '24 HOURS' 
            ELSE second_scheduled_departure_time - first_scheduled_arrival_time 
        END as normalized_second_leg,
        CASE WHEN second_scheduled_arrival_time - second_scheduled_departure_time < '00:00:00'::INTERVAL 
            THEN second_scheduled_arrival_time - second_scheduled_departure_time + INTERVAL '24 HOURS' 
            ELSE second_scheduled_arrival_time - second_scheduled_departure_time 
        END as normalized_third_leg
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
        second_scheduled_arrival_time
    FROM max_1_transfer_and_non_circular_flights_with_travel_times
    WHERE normalized_first_leg + normalized_second_leg + normalized_third_leg <= INTERVAL '24 HOURS'
) SELECT
    first_flight as first_flight_no,
    second_flight as second_flight_no,
    first_departure_airport as origin_airport,
    COALESCE(second_arrival_airport, first_arrival_airport) as destination_airport_code,
    CASE WHEN second_flight IS NOT NULL THEN first_arrival_airport END as transfer_airport_code,
    first_scheduled_departure_time as first_scheduled_departure_time,
    CASE WHEN second_flight IS NOT NULL THEN first_scheduled_arrival_time END as transfer_airport_arrival_time,
    CASE WHEN second_flight IS NOT NULL THEN second_scheduled_departure_time END as transfer_airport_departure_time,
    COALESCE(second_scheduled_arrival_time, first_scheduled_arrival_time) as destination_arrival_time
FROM max_1_transfer_and_non_circular_flights_within_24hours AS valid_routes
```

It uses our `jwan.test_routes` table.

__ 
3. Dealing with time requirement of <= 24 hours was tricky.

I basically took the 3 legs, normalized them by doing arrival_time - departure_time and adding 24 hours if it was negative. I add up the 3 legs and if they're less than or equal to 24 hours, we take those rows.
```
max_1_transfer_and_non_circular_flights_with_travel_times AS (
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
        CASE WHEN first_scheduled_arrival_time - first_scheduled_departure_time < '00:00:00'::INTERVAL
            THEN first_scheduled_arrival_time - first_scheduled_departure_time + INTERVAL '24 HOURS' 
            ELSE first_scheduled_arrival_time - first_scheduled_departure_time 
        END as normalized_first_leg,
        CASE WHEN second_scheduled_departure_time - first_scheduled_arrival_time < '00:00:00'::INTERVAL
            THEN second_scheduled_departure_time - first_scheduled_arrival_time + INTERVAL '24 HOURS' 
            ELSE second_scheduled_departure_time - first_scheduled_arrival_time 
        END as normalized_second_leg,
        CASE WHEN second_scheduled_arrival_time - second_scheduled_departure_time < '00:00:00'::INTERVAL 
            THEN second_scheduled_arrival_time - second_scheduled_departure_time + INTERVAL '24 HOURS' 
            ELSE second_scheduled_arrival_time - second_scheduled_departure_time 
        END as normalized_third_leg
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
        second_scheduled_arrival_time
    FROM max_1_transfer_and_non_circular_flights_with_travel_times
    WHERE normalized_first_leg + normalized_second_leg + normalized_third_leg <= INTERVAL '24 HOURS'
)
```
results in my test schema:

```
 first_flight | second_flight | first_departure_airport | first_arrival_airport | second_departure_airport | second_arrival_airport | first_scheduled_departure_time | first_scheduled_arrival_time | second_scheduled_departure_time | second_scheduled_arrival_time | normalized_first_leg | normalized_second_leg | normalized_third_leg
--------------+---------------+-------------------------+-----------------------+--------------------------+------------------------+--------------------------------+------------------------------+---------------------------------+-------------------------------+----------------------+-----------------------+----------------------
 PG0012       | PG0007        | GDZ                     | VKO                   | VKO                      | JOK                    | 07:55:00                       | 09:40:00                     | 09:40:00                        | 11:50:00                      | 01:45:00             | 00:00:00              | 02:10:00
 PG0033       | PG0012        | ESL                     | GDZ                   | GDZ                      | VKO                    | 13:50:00                       | 15:35:00                     | 07:55:00                        | 09:40:00                      | 01:45:00             | 16:20:00              | 01:45:00
(2 rows)
```
Passes the eyeball test.
