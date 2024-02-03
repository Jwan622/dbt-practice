# Notes I kept while developing the models
These are questions I need to answer for myself that came up over the course of development.

## Ticket Sales models
- make sure `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` is what I want there for prior 7 days
- What's the diff between extract and date_trunc functions for getting the day. Which do I want and why.

## Redemptions
When I enter the container and connect to the postgres instance (notes in the docs folder on how to do this), and run:
```postgresql
 select distinct cost from bookings
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
