WITH redemption_bookings AS (
    SELECT
        DATE_TRUNC('day', b.book_date) AS sale_date,
        COUNT(*) AS redemption_count
    FROM bookings b
    WHERE total_amount = -1 or total_amount = 0 or total_amount = -12345678.00
    GROUP BY sale_date
)

SELECT
    rb.sale_date AS date,
    COALESCE(rb.redemption_count, 0) AS redemption_bookings_count
FROM redemption_bookings rb;
