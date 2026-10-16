-- =====================================================
-- 00_data_cleaning.sql
-- Purpose: Build a cleaned version of the raw events table.
-- All later queries read from events_clean, not events.
-- =====================================================

-- Drop the view first so this file can be re-run without errors
DROP VIEW IF EXISTS events_clean;

CREATE VIEW events_clean AS
SELECT DISTINCT                      -- DISTINCT removes exact duplicate rows
  -- Fix mixed timestamp formats: turn '2019-10-01T10:00:00Z' into '2019-10-01 10:00:00 UTC'
  REPLACE(REPLACE(event_time, 'T', ' '), 'Z', ' UTC') AS event_time,

  -- Standardize text: 'PURCHASE', 'Purchase ' -> 'purchase'
  LOWER(TRIM(event_type)) AS event_type,

  product_id,
  category_code,                     -- left as-is; NULLs are handled in later queries

  -- Standardize brand names: ' Samsung ', 'SAMSUNG' -> 'samsung'
  LOWER(TRIM(brand)) AS brand,

  price,
  user_id,
  user_session
FROM events
WHERE user_id IS NOT NULL            -- can't count a user we can't identify
  AND price > 0                      -- removes zero and negative prices
  AND user_id < 900000000;           -- excludes the 4 bot users (IDs start at 900000000)