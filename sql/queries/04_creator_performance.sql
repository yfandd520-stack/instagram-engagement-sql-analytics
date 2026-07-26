-- Business question: Which creators generate attention most efficiently?
-- Techniques: event pre-aggregation, join-explosion prevention, normalized KPI.

WITH content_events AS (
  SELECT
    c.content_id,
    c.user_id,
    COALESCE(v.views, 0) AS views,
    COALESCE(v.watch_seconds, 0) AS watch_seconds,
    COALESCE(l.likes, 0) AS likes,
    COALESCE(cm.comments, 0) AS comments
  FROM content AS c
  LEFT JOIN (
    SELECT
      content_id,
      COUNT(*) AS views,
      SUM(time_spent_seconds) AS watch_seconds
    FROM view_logs
    GROUP BY content_id
  ) AS v ON c.content_id = v.content_id
  LEFT JOIN (
    SELECT content_id, COUNT(*) AS likes
    FROM likes
    GROUP BY content_id
  ) AS l ON c.content_id = l.content_id
  LEFT JOIN (
    SELECT content_id, COUNT(*) AS comments
    FROM comments
    GROUP BY content_id
  ) AS cm ON c.content_id = cm.content_id
)
SELECT
  u.username AS creator,
  u.account_type,
  COUNT(e.content_id) AS content_created,
  SUM(e.views) AS total_views,
  SUM(e.watch_seconds) AS total_watch_seconds,
  SUM(e.likes) AS total_likes,
  SUM(e.comments) AS total_comments,
  ROUND(SUM(e.watch_seconds) / NULLIF(COUNT(e.content_id), 0), 2)
    AS watch_seconds_per_content
FROM users AS u
JOIN content_events AS e ON u.user_id = e.user_id
GROUP BY u.user_id, u.username, u.account_type
ORDER BY total_watch_seconds DESC, creator;
