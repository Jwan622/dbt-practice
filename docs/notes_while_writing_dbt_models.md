# Notes I kept while developing the models

These are notes I took for myself while writing the models. Also, I left some questions I need to answer for myself that came up over the course of development of the dbt models

## Ticket Sales models
- I threw all the info in one model and it passed the eyeball test. This was more straightforward. Writing the tests were a bit harder. Incorporated some dbt_utils tests.

### Results for Ticket Sales Query

It seemed odd to me that the daily total tickets increased over time which made me believe I was accidentally aggregating instead of just counting tickets day by day... but it seems to checkout when I run simple `where` queries. Below are the results for day 2 and 3:

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


___

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


**AMENDMENT**

Y'all are tricky.
LOL... I did one last quick eyeball check and found these values in the `bookings` table:

```
select distinct total_amount from bookings order by total_amount DESC;
```

results:

```
total_amount
--------------
  99999999.00
  88888888.00
   1204500.00
   1116700.00
```

I think those are probably outliers too used to signify a redemption. I might add those.... but I might not since they are outlierishly high. Why would those be redemptions. I'm actually not sure how to treat those values tbh.


### Additional thoughts about Redemption Bookings
I wrote an outlier test that I think is useful. When that fails on a day when we run this model incrementally (even though we're doing full refreshes right now), it'd be nice if it sent a slack messages to an alerts channel. If there is an outlierishly high redemption for a day... perhaps we wrote a bug enabling too many redemptions.


____
## Valid and bookable routes

Harder problem here....mainly because I was unclear what the question was asking. I screwed it up the first time. But by inspecting the data, I think I figured out what the question meant!

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

And then finally f3 `array_aggs` the days of the week together. Notice it does not `GROUP BY` the days of the week column so that `array_agg` function can aggregate the days of the week the routes fly. I noticed at first the departure and arrival times didn't have days and so I stupidly assumped  these flights flew daily. I completely missed the `days_of_week` column the first time around so had to adjust my code.

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

Those are 710 individual routes. That's going to balloon when we make transfer routes from them.

### Questions
Quite a few questions and slight gotchas came up on this. I'll tackle one at a time.

- What does max one transfer mean? Should we include single-leg flights? I made the decision to include non-transfer routes as valid routes.
- Do some routes start and end at the same airport ever? Or do you mean in transfer flights... a valid route cannot start and end in the same city. But isn't that just a RT flight? Isn't that a valid route?
- When we crossover the next day... the transfer flight has to be on a day later right? I actually couldn't find any in the dataset but I did adjust my code to account for this. This part was tricky.
- I included layover times in the 24h total_travel_time calculation. That was the time between the second flight's departure time and the first flight's arrival time. Is that right?

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

So there are no departure airports that are not arrival airports in the routes view. Dammit. So my query is wrong.

Okay so I think I understood the question wrong. The "max" part of that question just means limit your universe of potential routes to just 1 transfer routes or 0 transfer routes even though there are definitely transfer routes with 2 or 3 hops. You can actually have infinite transfers. There are no orphan destinations.

I created a test schema named `jwan` and some dummy tables in the schema to play around with so I can be more sure of my queries.
my test table:
```
  flight_no | departure_airport |      departure_airport_name      | departure_city  | arrival_airport |        arrival_airport_name        | arrival_city | aircraft_code | scheduled_departure | scheduled_arrival | duration |  days_of_week
-----------+-------------------+----------------------------------+-----------------+-----------------+------------------------------------+--------------+---------------+---------------------+-------------------+----------+-----------------
 PG0300    | ESL               | Elista Airport                   | Elista          | SVO             | Sheremetyevo International Airport | Moscow       | CN1           | 08:20:00            | 12:10:00          | 03:50:00 | {1,2,3,4,5,6,7}
 PG0033    | ESL               | Elista Airport                   | Elista          | GDZ             | Gelendzhik Airport                 | Gelendzhik   | CN1           | 13:50:00            | 15:35:00          | 01:45:00 | {2,6}
 PG0007    | VKO               | Vnukovo International Airport    | Moscow          | JOK             | Yoshkar-Ola Airport                | Yoshkar-Ola  | CN1           | 09:40:00            | 11:50:00          | 02:10:00 | {1,2,3,4,5,6,7}
 PG0109    | MRV               | Mineralnyye Vody Airport         | Mineralnye Vody | GDX             | Sokol Airport                      | Magadan      | 763           | 17:30:00            | 02:15:00          | 08:45:00 | {7}
 PG0267    | GDX               | Sokol Airport                    | Magadan         | IKT             | Irkutsk Airport                    | Irkutsk      | SU9           | 07:05:00            | 11:00:00          | 03:55:00 | {3,7}
 PG0208    | DME               | Domodedovo International Airport | Moscow          | KHV             | Khabarovsk-Novy Airport            | Khabarovsk   | 763           | 17:40:00            | 01:40:00          | 08:00:00 | {1,2,3,4,5,6,7}
 PG0705    | SCW               | Syktyvkar Airport                | Syktyvkar       | GDX             | Sokol Airport                      | Magadan      | 763           | 17:45:00            | 00:10:00          | 06:25:00 | {7}
 PG0088    | KHV               | Khabarovsk-Novy Airport          | Khabarovsk      | DYR             | Ugolny Airport                     | Anadyr       | 319           | 00:20:00            | 04:25:00          | 04:05:00 | {6}
 PG0012    | GDZ               | Gelendzhik Airport               | Gelendzhik      | VKO             | Vnukovo International Airport      | Moscow       | CR2           | 07:55:00            | 09:40:00          | 01:45:00 | {2,4,6}
 PG0034    | GDZ               | Gelendzhik Airport               | Gelendzhik      | ESL             | Elista Airport                     | Elista       | CN1           | 08:25:00            | 10:10:00          | 01:45:00 | {3,7}
 PG0049    | VKO               | Vnukovo International Airport    | Moscow          | GDZ             | Gelendzhik Airport                 | Gelendzhik   | CR2           | 10:05:00            | 11:50:00          | 01:45:00 | {2,5,7}
(11 rows)
```

It has just 10 rows. **But the thing to note here is that MRV -> GDX is an overnight flight into the next day so any connecting in GDX will have to start one day later to be a valid route. Also, there are some invalid routes because they start and end in the same city like ESL > GDZ > ESL. **  

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
Since there are none, I think that requirement actually refers to routes with a transfer that start and end at the same airport. I think that's not a valid route. Let's see how many of those exist. But why is that not a valid route? Who knows... maybe that's just to ensure people don't fly somewhere and come right back home the same day. But isn't that a round-trip ticket? Isn't that route valid? Oh well....nvm. I wish I could eliminate same day count trips but the timestamps are just `time` without a date!

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

and some edge cases:
```
insert into jwan.test_routes select * from routes where flight_no = 'PG0109';
insert into jwan.test_routes select * from routes where flight_no = 'PG0267';
insert into jwan.test_routes select * from routes where flight_no = 'PG0208';
insert into jwan.test_routes select * from routes where flight_no = 'PG0705';
insert into jwan.test_routes select * from routes where flight_no = 'PG0088';
```

Final test data:
```
 flight_no | departure_airport |      departure_airport_name      | departure_city  | arrival_airport |        arrival_airport_name        | arrival_city | aircraft_code | scheduled_departure | scheduled_arrival | duration |  days_of_week
-----------+-------------------+----------------------------------+-----------------+-----------------+------------------------------------+--------------+---------------+---------------------+-------------------+----------+-----------------
 PG0300    | ESL               | Elista Airport                   | Elista          | SVO             | Sheremetyevo International Airport | Moscow       | CN1           | 08:20:00            | 12:10:00          | 03:50:00 | {1,2,3,4,5,6,7}
 PG0033    | ESL               | Elista Airport                   | Elista          | GDZ             | Gelendzhik Airport                 | Gelendzhik   | CN1           | 13:50:00            | 15:35:00          | 01:45:00 | {2,6}
 PG0007    | VKO               | Vnukovo International Airport    | Moscow          | JOK             | Yoshkar-Ola Airport                | Yoshkar-Ola  | CN1           | 09:40:00            | 11:50:00          | 02:10:00 | {1,2,3,4,5,6,7}
 PG0109    | MRV               | Mineralnyye Vody Airport         | Mineralnye Vody | GDX             | Sokol Airport                      | Magadan      | 763           | 17:30:00            | 02:15:00          | 08:45:00 | {7}
 PG0267    | GDX               | Sokol Airport                    | Magadan         | IKT             | Irkutsk Airport                    | Irkutsk      | SU9           | 07:05:00            | 11:00:00          | 03:55:00 | {3,7}
 PG0208    | DME               | Domodedovo International Airport | Moscow          | KHV             | Khabarovsk-Novy Airport            | Khabarovsk   | 763           | 17:40:00            | 01:40:00          | 08:00:00 | {1,2,3,4,5,6,7}
 PG0705    | SCW               | Syktyvkar Airport                | Syktyvkar       | GDX             | Sokol Airport                      | Magadan      | 763           | 17:45:00            | 00:10:00          | 06:25:00 | {7}
 PG0088    | KHV               | Khabarovsk-Novy Airport          | Khabarovsk      | DYR             | Ugolny Airport                     | Anadyr       | 319           | 00:20:00            | 04:25:00          | 04:05:00 | {6}
 PG0012    | GDZ               | Gelendzhik Airport               | Gelendzhik      | VKO             | Vnukovo International Airport      | Moscow       | CR2           | 07:55:00            | 09:40:00          | 01:45:00 | {2,4,6}
 PG0034    | GDZ               | Gelendzhik Airport               | Gelendzhik      | ESL             | Elista Airport                     | Elista       | CN1           | 08:25:00            | 10:10:00          | 01:45:00 | {3,7}
 PG0049    | VKO               | Vnukovo International Airport    | Moscow          | GDZ             | Gelendzhik Airport                 | Gelendzhik   | CR2           | 10:05:00            | 11:50:00          | 01:45:00 | {2,5,7}
(11 rows)
```

When we run our final query we get this which looks right:

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

Final test model:

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
        NULL::time without time zone as second_scheduled_departure_time,
        route1.scheduled_arrival as first_scheduled_arrival_time,
        NULL::time without time zone as second_scheduled_arrival_time,
        route1.duration as first_duration,
        NULL::INTERVAL as second_duration,
        route1.days_of_week as first_days_of_week,
        NULL::INTEGER[] as second_days_of_week
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
        route2.scheduled_departure as second_scheduled_departure_time,
        route1.scheduled_arrival as first_scheduled_arrival_time,
        route2.scheduled_arrival as second_scheduled_arrival_time,
        route1.duration as first_duration,
        route2.duration as second_duration,
        route1.days_of_week as first_days_of_week,
        route2.days_of_week as second_days_of_week
    FROM jwan.test_routes AS route1
    INNER JOIN jwan.test_routes AS route2
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
```

It uses our `jwan.test_routes` table.

results:

```
 first_flight_no | second_flight_no | origin_airport_code | destination_airport_code | transfer_airport_code | first_scheduled_departure_time | transfer_airport_arrival_time | transfer_airport_departure_time | destination_arrival_time |  days_of_week   | total_travel_time
-----------------+------------------+---------------------+--------------------------+-----------------------+--------------------------------+-------------------------------+---------------------------------+--------------------------+-----------------+-------------------
 PG0012          | PG0007           | GDZ                 | JOK                      | VKO                   | 07:55:00                       | 09:40:00                      | 09:40:00                        | 11:50:00                 | {2,4,6}         | 03:55:00
 PG0300          |                  | ESL                 | SVO                      |                       | 08:20:00                       |                               |                                 | 12:10:00                 | {1,2,3,4,5,6,7} | 03:50:00
 PG0033          |                  | ESL                 | GDZ                      |                       | 13:50:00                       |                               |                                 | 15:35:00                 | {2,6}           | 01:45:00
 PG0007          |                  | VKO                 | JOK                      |                       | 09:40:00                       |                               |                                 | 11:50:00                 | {1,2,3,4,5,6,7} | 02:10:00
 PG0109          |                  | MRV                 | GDX                      |                       | 17:30:00                       |                               |                                 | 02:15:00                 | {7}             | 08:45:00
 PG0267          |                  | GDX                 | IKT                      |                       | 07:05:00                       |                               |                                 | 11:00:00                 | {3,7}           | 03:55:00
 PG0208          |                  | DME                 | KHV                      |                       | 17:40:00                       |                               |                                 | 01:40:00                 | {1,2,3,4,5,6,7} | 08:00:00
 PG0705          |                  | SCW                 | GDX                      |                       | 17:45:00                       |                               |                                 | 00:10:00                 | {7}             | 06:25:00
 PG0088          |                  | KHV                 | DYR                      |                       | 00:20:00                       |                               |                                 | 04:25:00                 | {6}             | 04:05:00
 PG0012          |                  | GDZ                 | VKO                      |                       | 07:55:00                       |                               |                                 | 09:40:00                 | {2,4,6}         | 01:45:00
 PG0034          |                  | GDZ                 | ESL                      |                       | 08:25:00                       |                               |                                 | 10:10:00                 | {3,7}           | 01:45:00
 PG0049          |                  | VKO                 | GDZ                      |                       | 10:05:00                       |                               |                                 | 11:50:00                 | {2,5,7}         | 01:45:00
(12 rows)
```
__ 

Flights like GDZ -> ESL -> SVO were eliminated because they took too long. This one's layover takes it over the 24h mark. Same with VKO -> GDZ -> ESL. the day is viable on the 3rd but the flight time is too long.

## Edge cases

At sunday 10pm, I just noticed flight `PG0109`. God dammit. Need to change my logic for routes. Holy god.
In short, if an overnight flight occurs on the first leg, the flyer can only get second leg flights on the next day. So the first leg flys on day_of_week = 2 but it's an overnight, then the next flight has to be day_of_week = 3. We need to write logic to handle this.

The first leg is an overnight if:
```
CASE WHEN first_scheduled_arrival_time - first_scheduled_departure_time < '00:00:00'::INTERVAL OR second_scheduled_departure_time - first_scheduled_arrival_time < '00:00:00'::INTERVAL 
            THEN 1 ELSE 0 
        END as is_first_flight_crossover_to_next_day,
```

In the event of an overnight, we can adjust the days_of_week array like so:

```
CASE WHEN is_first_flight_crossover_to_next_day = 1 THEN ARRAY(SELECT unnest(first_days_of_week) + 1) END AS first_days_of_week_adjusted_because_overnight,
```
Like... this is probably not a route because it takes off on Sat but there is no flight on sunday at GDX:

```
flight_no | departure_airport |      departure_airport_name      | departure_city  | arrival_airport |        arrival_airport_name        | arrival_city | aircraft_code | scheduled_departure | scheduled_arrival | duration |  days_of_week
PG0109    | MRV               | Mineralnyye Vody Airport         | Mineralnye Vody | GDX             | Sokol Airport                      | Magadan      | 763           | 17:30:00            | 02:15:00          | 08:45:00 | {7}
 PG0267    | GDX               | Sokol Airport                    | Magadan         | IKT             | Irkutsk Airport                    | Irkutsk      | SU9           | 07:05:00            | 11:00:00          | 03:55:00 | {3,7}
```

That needs to not come up. Let's handle this.

But this pair needs to appear because it's under 24 hours and the 7 of the first leg DME -> KRO should turn into a 1 when we adjust the day and 1 is a day of week for KRO -> EYK

```
PG0370    | DME               | Domodedovo International Airport | Moscow          | KRO             | Kurgan Airport                     | Kurgan       | CR2           | 08:50:00            | 11:15:00          | 02:25:00 | {2,4,7}
 PG0367    | KRO               | Kurgan Airport                   | Kurgan          | EYK             | Beloyarskiy Airport                | Beloyarsky   | CN1           | 04:25:00            | 07:25:00          | 03:00:00 | {1,4}
```

and it does... hell yeah

```
 first_flight_no | second_flight_no | origin_airport_code | destination_airport_code | transfer_airport_code | first_scheduled_departure_time | transfer_airport_arrival_time | transfer_airport_departure_time | destination_arrival_time |  days_of_week   | total_travel_time
-----------------+------------------+---------------------+--------------------------+-----------------------+--------------------------------+-------------------------------+---------------------------------+--------------------------+-----------------+-------------------
 PG0012          | PG0007           | GDZ                 | JOK                      | VKO                   | 07:55:00                       | 09:40:00                      | 09:40:00                        | 11:50:00                 | {2,4,6}         | 03:55:00
 PG0370          | PG0367           | DME                 | EYK                      | KRO                   | 08:50:00                       | 11:15:00                      | 04:25:00                        | 07:25:00                 | {1}             | 22:35:00
 PG0300          |                  | ESL                 | SVO                      |                       | 08:20:00                       |                               |                                 | 12:10:00                 | {1,2,3,4,5,6,7} | 03:50:00
 PG0033          |                  | ESL                 | GDZ                      |
```
