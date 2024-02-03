WITH daily_ticket_sales AS (
    SELECT
        DATE_TRUNC('day', b.book_date) AS sale_date,
        COUNT(t.ticket_no) AS total_tickets
    FROM bookings b
    JOIN tickets t ON b.book_ref = t.book_ref
    GROUP BY sale_date
),

rolling_7d_ticket_sales AS (
    SELECT
        sale_date,
        SUM(total_tickets) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7_days_total
    FROM daily_ticket_sales
),

rolling_28d_ticket_sales AS (
    SELECT
        sale_date,
        SUM(total_tickets) OVER (ORDER BY sale_date ROWS BETWEEN 27 PRECEDING AND CURRENT ROW) AS rolling_28_days_total
    FROM daily_ticket_sales
)
SELECT
    dts.sale_date AS date,
    dts.total_tickets AS daily_total_tickets,
    rolling_7d.rolling_7_days_total,
    rolling_28d.rolling_28_days_total
FROM daily_ticket_sales dts
LEFT JOIN rolling_7d_ticket_sales AS rolling_7d
    ON dts.sale_date = rolling_7d.sale_date
LEFT JOIN rolling_28d_ticket_sales AS rolling_28d
    ON dts.sale_date = rolling_28d.sale_date