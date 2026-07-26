-- Business question: Which content format creates the strongest engagement?
-- Techniques: CTEs, LEFT JOINs, conditional aggregation, rate calculation.

WITH view_metrics AS (
  SELECT
    content_id,
    COUNT(*) AS views,
    SUM(time_spent_seconds) AS watch_seconds,
    AVG(time_spent_seconds) AS avg_view_seconds,
    AVG(completion_rate) AS avg_completion_rate
  FROM view_logs
  GROUP BY content_id
),
like_metrics AS (
  SELECT content_id, COUNT(*) AS likes
  FROM likes
  GROUP BY content_id
),
comment_metrics AS (
  SELECT content_id, COUNT(*) AS comments
  FROM comments
  GROUP BY content_id
)
SELECT
  c.content_type,
  COUNT(*) AS content_items,
  COALESCE(SUM(v.views), 0) AS total_views,
  COALESCE(SUM(v.watch_seconds), 0) AS total_watch_seconds,
  ROUND(AVG(v.avg_view_seconds), 2) AS avg_seconds_per_view,
  ROUND(AVG(v.avg_completion_rate), 2) AS avg_completion_pct,
  COALESCE(SUM(l.likes), 0) AS total_likes,
  COALESCE(SUM(cm.comments), 0) AS total_comments
FROM content AS c
LEFT JOIN view_metrics AS v ON c.content_id = v.content_id
LEFT JOIN like_metrics AS l ON c.content_id = l.content_id
LEFT JOIN comment_metrics AS cm ON c.content_id = cm.content_id
GROUP BY c.content_type
ORDER BY total_watch_seconds DESC;
