-- =====================================================
-- 03_by_category.sql
-- Purpose: Find which product categories lose the most
-- users between cart and purchase.
-- =====================================================

SELECT
  category_code,
  COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS viewers,
  COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS carters,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS buyers,

  -- NULLIF turns a zero into NULL so we never divide by zero
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END), 0), 2)
        AS cart_to_purchase_pct
FROM events_clean
WHERE category_code IS NOT NULL      -- skip rows with a missing category
GROUP BY category_code
ORDER BY cart_to_purchase_pct;       -- lowest (worst) conversion first
