# Notes I kept while developing the models
These are questions I need to answer for myself that came up over the course of development.

## Ticket Sales models
- make sure `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` is what I want there for prior 7 days
- What's the diff between extract and date_trunc functions for getting the day. Which do I want and why.


### Results for Ticket Sales Query

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

and so to me, different airlines have different ways of implying redemptions.

1. But wait, do those `total_amounts` correspond to different airlines? If not, that's an issue. Usually airlines, I'd assume, have a single way of identifying a free redemption. So let's see what airline or flight company those amounts are associated with?
