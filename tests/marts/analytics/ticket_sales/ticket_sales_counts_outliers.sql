--I think an alert will do just fine
{{
    config(
        materialized='test',
        severity='warn'
    )
}}


WITH ticket_sales_stats_last_60d AS (
    SELECT
        date,
        daily_total_tickets,
        AVG(daily_total_tickets) OVER () AS mean_daily_total_tickets,
        STDDEV_POP(daily_total_tickets) OVER () AS std_dev_daily_total_tickets
    FROM dbt.ticket_sales_counts
    WHERE date >= (SELECT MAX(date) FROM dbt.ticket_sales_counts) - INTERVAL '60 days'
)
SELECT
    'Ticket count be wildin, they are too low!' AS test,
    date,
    daily_total_tickets,
    mean_daily_total_tickets,
    std_dev_daily_total_tickets,
    CASE
        WHEN daily_total_tickets > mean_daily_total_tickets + 2 * std_dev_daily_total_tickets THEN 'Outlier'
        ELSE 'Not an outlier'
    END AS outlier_status
FROM ticket_sales_stats_last_60d
WHERE daily_total_tickets < mean_daily_total_tickets - 2 * std_dev_daily_total_tickets
