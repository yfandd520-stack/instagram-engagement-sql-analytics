-- Business question: How does engagement differ by operating system and device?
-- Techniques: session-to-event join, distinct counts, normalized rate.

SELECT
  s.device_os,
  s.device_type,
  COUNT(DISTINCT s.session_id) AS sessions,
  COUNT(v.log_id) AS views,
  SUM(v.time_spent_seconds) AS total_watch_seconds,
  ROUND(AVG(v.time_spent_seconds), 2) AS avg_seconds_per_view,
  ROUND(AVG(v.completion_rate), 2) AS avg_completion_pct,
  ROUND(COUNT(v.log_id) / COUNT(DISTINCT s.session_id), 2)
    AS views_per_session
FROM sessions AS s
LEFT JOIN view_logs AS v ON s.session_id = v.session_id
GROUP BY s.device_os, s.device_type
ORDER BY total_watch_seconds DESC;
