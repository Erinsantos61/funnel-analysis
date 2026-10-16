-- =====================================================
-- 04_by_price_range.sql
-- Purpose: Test whether higher-priced products convert worse.
-- =====================================================

WITH priced AS (
  SELECT
    user_id,
    event_type,
    -- Group each event into a price bucket
    CASE
      WHEN price < 50   THEN '1. Under $50'
      WHEN price < 200  THEN '2. $50-199'
      WHEN price < 500  THEN '3. $200-499'
      WHEN price < 1000 THEN '4. $500-999'
      ELSE                   '5. $1000+'
    END AS price_range
  FROM events_clean
)
SELECT
  price_range,
  COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS carters,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS buyers,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END), 0), 2)
        AS cart_to_purchase_pct
FROM priced
GROUP BY price_range
ORDER BY price_range;