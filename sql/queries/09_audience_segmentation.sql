-- Business question: Which users qualify as high-value publishing audiences?
-- Techniques: UNION ALL, CTE, deduplication, GROUP_CONCAT segmentation.

WITH qualifying_signals AS (
  SELECT
    user_id,
    'creator_or_business' AS reason
  FROM users
  WHERE account_type IN ('creator', 'business')

  UNION ALL

  SELECT DISTINCT
    user_id,
    'posted_public_reel' AS reason
  FROM content
  WHERE content_type = 'Reel'
    AND visibility = 'public'
)
SELECT
  u.user_id,
  u.username,
  u.account_type,
  COUNT(*) AS qualifying_signals,
  GROUP_CONCAT(q.reason ORDER BY q.reason SEPARATOR ', ') AS reasons,
  CASE
    WHEN COUNT(*) >= 2 THEN 'priority'
    ELSE 'standard'
  END AS audience_segment
FROM qualifying_signals AS q
JOIN users AS u ON q.user_id = u.user_id
GROUP BY u.user_id, u.username, u.account_type
ORDER BY qualifying_signals DESC, u.username;
