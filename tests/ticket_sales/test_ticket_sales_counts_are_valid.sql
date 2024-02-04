{{
    config(
        materialized='test',
    )
}}

WITH cte AS (
    SELECT
    tsc.date,
    tsc.rolling_7_days_total AS actual_7d_total,
    SUM(tsc.daily_total_tickets) OVER (
        ORDER BY tsc.date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS expected_7d_total -- 6 not 7! god dammit.
    FROM dbt.ticket_sales_counts tsc
)
SELECT
    '7-day rolling total matches daily_total_tickets sum for last 7 days' AS test,
    date,
    actual_7d_total,
    expected_7d_total
FROM cte
WHERE actual_7d_total <> expected_7d_total

