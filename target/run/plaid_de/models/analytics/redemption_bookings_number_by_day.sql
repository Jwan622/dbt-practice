
  create view "bookings"."dbt"."redemption_bookings_number_by_day__dbt_tmp"
    
    
  as (
    SELECT
    DATE_TRUNC('day', b.book_date) AS date,
    COUNT(*) AS redemption_count
FROM bookings b
WHERE total_amount = -1
    OR total_amount = 0
    OR total_amount = -12345678.00
GROUP BY date
ORDER BY redemption_count desc
  );