-- Business question: Who likes content without commenting on the same item?
-- Techniques: correlated NOT EXISTS anti-join, aggregation, distinct counts.

SELECT
  u.user_id,
  u.username,
  u.account_type,
  COUNT(*) AS like_only_interactions,
  COUNT(DISTINCT l.content_id) AS distinct_content_liked
FROM likes AS l
JOIN users AS u ON l.user_id = u.user_id
WHERE NOT EXISTS (
  SELECT 1
  FROM comments AS cm
  WHERE cm.user_id = l.user_id
    AND cm.content_id = l.content_id
)
GROUP BY u.user_id, u.username, u.account_type
ORDER BY like_only_interactions DESC, u.username
LIMIT 10;
