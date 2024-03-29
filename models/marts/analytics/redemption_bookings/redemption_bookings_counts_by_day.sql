{{
    config(
        materialized='table',
    )
}}

SELECT
    DATE_TRUNC('day', b.book_date) AS date,
    COUNT(*) AS redemption_count
FROM bookings b
WHERE total_amount = -1
    OR total_amount = 0
    OR total_amount = -12345678.00
    OR total_amount = 99999999.00
    OR total_amount = 88888888.00
GROUP BY date
ORDER BY date asc
