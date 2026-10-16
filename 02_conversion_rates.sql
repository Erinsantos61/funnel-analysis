-- =====================================================
-- 02_conversion_rates.sql
-- Purpose: Calculate stage-to-stage and overall conversion rates,
-- and show how many users are lost at each step.
-- =====================================================

-- Step 1: count unique users at each stage (one row, three columns)
WITH funnel AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS viewers,
    COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS carters,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS buyers
  FROM events_clean
)

-- Step 2: turn those counts into percentages
SELECT
  viewers,
  carters,
  buyers,
  -- 100.0 (not 100) forces decimal division instead of whole-number division
  ROUND(100.0 * carters / viewers, 2) AS view_to_cart_pct,
  ROUND(100.0 * buyers  / carters, 2) AS cart_to_purchase_pct,
  ROUND(100.0 * buyers  / viewers, 2) AS overall_pct,
  viewers - carters AS lost_before_cart,      -- viewers who never added to cart
  carters - buyers  AS lost_before_purchase   -- cart abandoners
FROM funnel;