-- Business question: Which individual posts hold the most attention?
-- Techniques: multi-table joins, CTE, aggregation, DENSE_RANK window function.

WITH content_attention AS (
  SELECT
    c.content_id,
    u.username AS creator,
    c.content_type,
    c.caption,
    COUNT(v.log_id) AS views,
    SUM(v.time_spent_seconds) AS total_watch_seconds,
    ROUND(AVG(v.completion_rate), 2) AS avg_completion_pct
  FROM content AS c
  JOIN users AS u ON c.user_id = u.user_id
  JOIN view_logs AS v ON c.content_id = v.content_id
  GROUP BY
    c.content_id,
    u.username,
    c.content_type,
    c.caption
)
SELECT
  DENSE_RANK() OVER (ORDER BY total_watch_seconds DESC) AS attention_rank,
  content_id,
  creator,
  content_type,
  caption,
  views,
  total_watch_seconds,
  avg_completion_pct
FROM content_attention
ORDER BY attention_rank, content_id
LIMIT 10;
