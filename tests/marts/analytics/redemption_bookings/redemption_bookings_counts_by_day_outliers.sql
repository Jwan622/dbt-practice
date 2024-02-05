--I think an alert will do just fine
{{
    config(
        materialized='test',
        severity='warn'
    )
}}


WITH redemption_stats AS (
    SELECT
        date,
        redemption_count,
        AVG(redemption_count) OVER () AS mean_redemption_count,
        STDDEV_POP(redemption_count) OVER () AS std_dev_redemption_count
    FROM dbt.redemption_bookings_counts_by_day
)
SELECT
    'Redemption count be wildin, there are too many!' AS test,
    date,
    redemption_count,
    mean_redemption_count,
    std_dev_redemption_count,
    CASE
        WHEN redemption_count > {{ calculate_threshold('mean_redemption_count', 'std_dev_redemption_count', 2) }} THEN 'Outlier'
        ELSE 'Not an outlier'
    END AS outlier_status
FROM redemption_stats
WHERE redemption_count > {{ calculate_threshold('mean_redemption_count', 'std_dev_redemption_count', 2) }}
