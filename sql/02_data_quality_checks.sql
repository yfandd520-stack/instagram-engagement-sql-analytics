-- Data-quality checks for the synthetic portfolio dataset.

USE instagram_engagement_analytics;

-- 1. Expected versus actual row counts.
WITH expected_counts AS (
  SELECT 'users' AS table_name, 10 AS expected_rows
  UNION ALL SELECT 'content', 15
  UNION ALL SELECT 'sessions', 12
  UNION ALL SELECT 'hashtags', 12
  UNION ALL SELECT 'content_hashtags', 34
  UNION ALL SELECT 'likes', 55
  UNION ALL SELECT 'comments', 30
  UNION ALL SELECT 'view_logs', 50
),
actual_counts AS (
  SELECT 'users' AS table_name, COUNT(*) AS actual_rows FROM users
  UNION ALL SELECT 'content', COUNT(*) FROM content
  UNION ALL SELECT 'sessions', COUNT(*) FROM sessions
  UNION ALL SELECT 'hashtags', COUNT(*) FROM hashtags
  UNION ALL SELECT 'content_hashtags', COUNT(*) FROM content_hashtags
  UNION ALL SELECT 'likes', COUNT(*) FROM likes
  UNION ALL SELECT 'comments', COUNT(*) FROM comments
  UNION ALL SELECT 'view_logs', COUNT(*) FROM view_logs
)
SELECT
  e.table_name,
  e.expected_rows,
  a.actual_rows,
  CASE WHEN e.expected_rows = a.actual_rows THEN 'PASS' ELSE 'FAIL' END
    AS check_status
FROM expected_counts AS e
JOIN actual_counts AS a USING (table_name)
ORDER BY e.table_name;

-- 2. Foreign-key orphan checks. Every result should be zero.
SELECT
  'content.user_id -> users.user_id' AS relationship,
  COUNT(*) AS orphan_rows
FROM content AS c
LEFT JOIN users AS u ON c.user_id = u.user_id
WHERE u.user_id IS NULL
UNION ALL
SELECT 'sessions.user_id -> users.user_id', COUNT(*)
FROM sessions AS s
LEFT JOIN users AS u ON s.user_id = u.user_id
WHERE u.user_id IS NULL
UNION ALL
SELECT 'content_hashtags.content_id -> content.content_id', COUNT(*)
FROM content_hashtags AS ch
LEFT JOIN content AS c ON ch.content_id = c.content_id
WHERE c.content_id IS NULL
UNION ALL
SELECT 'content_hashtags.hashtag_id -> hashtags.hashtag_id', COUNT(*)
FROM content_hashtags AS ch
LEFT JOIN hashtags AS h ON ch.hashtag_id = h.hashtag_id
WHERE h.hashtag_id IS NULL
UNION ALL
SELECT 'likes.user_id -> users.user_id', COUNT(*)
FROM likes AS l
LEFT JOIN users AS u ON l.user_id = u.user_id
WHERE u.user_id IS NULL
UNION ALL
SELECT 'likes.content_id -> content.content_id', COUNT(*)
FROM likes AS l
LEFT JOIN content AS c ON l.content_id = c.content_id
WHERE c.content_id IS NULL
UNION ALL
SELECT 'comments.user_id -> users.user_id', COUNT(*)
FROM comments AS cm
LEFT JOIN users AS u ON cm.user_id = u.user_id
WHERE u.user_id IS NULL
UNION ALL
SELECT 'comments.content_id -> content.content_id', COUNT(*)
FROM comments AS cm
LEFT JOIN content AS c ON cm.content_id = c.content_id
WHERE c.content_id IS NULL
UNION ALL
SELECT 'view_logs.content_id -> content.content_id', COUNT(*)
FROM view_logs AS v
LEFT JOIN content AS c ON v.content_id = c.content_id
WHERE c.content_id IS NULL
UNION ALL
SELECT 'view_logs.session_id -> sessions.session_id', COUNT(*)
FROM view_logs AS v
LEFT JOIN sessions AS s ON v.session_id = s.session_id
WHERE s.session_id IS NULL;

-- 3. Domain and consistency checks. Every issue count should be zero.
SELECT
  'session duration matches timestamps' AS quality_rule,
  SUM(
    CASE
      WHEN TIMESTAMPDIFF(SECOND, start_time, end_time) <> session_duration
      THEN 1 ELSE 0
    END
  ) AS issue_rows
FROM sessions
UNION ALL
SELECT
  'completion rate is between 0 and 100',
  SUM(CASE WHEN completion_rate NOT BETWEEN 0 AND 100 THEN 1 ELSE 0 END)
FROM view_logs
UNION ALL
SELECT
  'sentiment score is between -1 and 1',
  SUM(CASE WHEN sentiment_score NOT BETWEEN -1 AND 1 THEN 1 ELSE 0 END)
FROM comments
UNION ALL
SELECT
  'stored comment length matches text length',
  SUM(CASE WHEN CHAR_LENGTH(comment_text) <> comment_length THEN 1 ELSE 0 END)
FROM comments
UNION ALL
SELECT
  'no duplicate user-content likes',
  COUNT(*)
FROM (
  SELECT user_id, content_id
  FROM likes
  GROUP BY user_id, content_id
  HAVING COUNT(*) > 1
) AS duplicate_likes;
