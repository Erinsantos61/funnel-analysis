-- =====================================================
-- 06_time_to_purchase.sql
-- Purpose: Measure how long buyers take between their
-- first view and their first purchase.
-- =====================================================

-- Step 1: for each user, find the earliest view and earliest purchase
WITH first_events AS (
  SELECT
    user_id,
    MIN(CASE WHEN event_type = 'view'     THEN event_time END) AS first_view,
    MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase
  FROM events_clean
  GROUP BY user_id
),

-- Step 2: hours between the two (SUBSTR drops the ' UTC' so julianday can read it)
gaps AS (
  SELECT
    user_id,
    (julianday(SUBSTR(first_purchase, 1, 19))
      - julianday(SUBSTR(first_view, 1, 19))) * 24 AS hours_to_purchase
  FROM first_events
  WHERE first_view IS NOT NULL
    AND first_purchase IS NOT NULL
)

-- Step 3: group buyers into time buckets
SELECT
  CASE
    WHEN hours_to_purchase < 1   THEN '1. Under 1 hour'
    WHEN hours_to_purchase < 24  THEN '2. 1-24 hours'
    WHEN hours_to_purchase < 168 THEN '3. 1-7 days'
    ELSE                              '4. Over 7 days'
  END AS time_to_purchase,
  COUNT(*) AS buyers,
  -- share of all buyers falling in each bucket
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_buyers
FROM gaps
WHERE hours_to_purchase >= 0
GROUP BY time_to_purchase
ORDER BY time_to_purchase;