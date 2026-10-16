-- =====================================================
-- 05_by_time_of_day.sql
-- Purpose: See whether conversion differs by time of day.
-- =====================================================

WITH timed AS (
  SELECT
    user_id,
    event_type,
    -- Hour is characters 12-13 of 'YYYY-MM-DD HH:MM:SS UTC'
    CAST(SUBSTR(event_time, 12, 2) AS INTEGER) AS hr
  FROM events_clean
),
bucketed AS (
  SELECT
    user_id,
    event_type,
    CASE
      WHEN hr BETWEEN 0  AND 5  THEN '1. Night (12am-5am)'
      WHEN hr BETWEEN 6  AND 11 THEN '2. Morning (6am-11am)'
      WHEN hr BETWEEN 12 AND 17 THEN '3. Afternoon (12pm-5pm)'
      ELSE                           '4. Evening (6pm-11pm)'
    END AS time_of_day
  FROM timed
)
SELECT
  time_of_day,
  COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS viewers,
  COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS carters,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS buyers,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2)
        AS view_to_cart_pct,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END), 0), 2)
        AS cart_to_purchase_pct
FROM bucketed
GROUP BY time_of_day
ORDER BY time_of_day;