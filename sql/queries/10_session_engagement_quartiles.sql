-- Business question: Which sessions show the deepest engagement?
-- Techniques: session-level CTE, LEFT JOIN, NTILE window segmentation.

WITH session_metrics AS (
  SELECT
    s.session_id,
    u.username,
    s.device_os,
    s.device_type,
    ROUND(s.session_duration / 60.0, 2) AS session_minutes,
    COUNT(v.log_id) AS views,
    COALESCE(SUM(v.time_spent_seconds), 0) AS total_watch_seconds,
    ROUND(AVG(v.completion_rate), 2) AS avg_completion_pct
  FROM sessions AS s
  JOIN users AS u ON s.user_id = u.user_id
  LEFT JOIN view_logs AS v ON s.session_id = v.session_id
  GROUP BY
    s.session_id,
    u.username,
    s.device_os,
    s.device_type,
    s.session_duration
),
ranked_sessions AS (
  SELECT
    session_metrics.*,
    NTILE(4) OVER (
      ORDER BY total_watch_seconds DESC, session_id
    ) AS engagement_quartile
  FROM session_metrics
)
SELECT
  session_id,
  username,
  device_os,
  device_type,
  session_minutes,
  views,
  total_watch_seconds,
  avg_completion_pct,
  engagement_quartile
FROM ranked_sessions
ORDER BY engagement_quartile, total_watch_seconds DESC, session_id;
