WITH daily_metrics AS (
  SELECT
    date_trunc('day', booking_date) AS date,
    COUNT(*) AS total_tickets_daily
  FROM bookings
  GROUP BY date
),

rolling_7_metrics_from_daily_metrics AS (
  SELECT
    date,
    SUM(total_tickets_daily) OVER (
      ORDER BY date
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS total_tickets_rolling_7
  FROM daily_metrics
),

rolling_28_metrics_from_daily_metrics AS (
  SELECT
    date,
    SUM(total_tickets_daily) OVER (
      ORDER BY date
      ROWS BETWEEN 27 PRECEDING AND CURRENT ROW
    ) AS total_tickets_rolling_28
  FROM daily_metrics
)

SELECT
  daily_metrics.date,
  daily_metrics.total_tickets_daily,
  rolling_7_metrics_from_daily_metrics.total_tickets_rolling_7,
  rolling_28_metrics_from_daily_metrics.total_tickets_rolling_28
FROM daily_metrics
LEFT JOIN rolling_7_metrics_from_daily_metrics ON daily_metrics.date = rolling_7_metrics_from_daily_metrics.date
LEFT JOIN rolling_28_metrics_from_daily_metrics ON daily_metrics.date = rolling_28_metrics_from_daily_metrics.date;
