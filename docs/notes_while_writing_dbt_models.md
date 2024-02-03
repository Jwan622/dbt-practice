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
