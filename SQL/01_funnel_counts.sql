-- =====================================================
-- 01_funnel_counts.sql
-- Purpose: Count unique users at each funnel stage.
-- =====================================================

SELECT
  event_type,
  COUNT(DISTINCT user_id) AS users   -- DISTINCT so a user with 10 views counts once
FROM events_clean
WHERE event_type IN ('view', 'cart', 'purchase')  -- ignore remove_from_cart
GROUP BY event_type;