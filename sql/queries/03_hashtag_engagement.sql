-- Business question: Which hashtags are associated with stronger viewing behavior?
-- Techniques: many-to-many bridge traversal, joins, aggregation, ranking.

SELECT
  DENSE_RANK() OVER (
    ORDER BY COUNT(v.log_id) DESC, AVG(v.time_spent_seconds) DESC
  ) AS engagement_rank,
  h.hashtag_text,
  h.category,
  COUNT(DISTINCT ch.content_id) AS tagged_content_items,
  COUNT(v.log_id) AS linked_views,
  SUM(v.time_spent_seconds) AS linked_watch_seconds,
  ROUND(AVG(v.time_spent_seconds), 2) AS avg_seconds_per_view
FROM hashtags AS h
JOIN content_hashtags AS ch ON h.hashtag_id = ch.hashtag_id
JOIN view_logs AS v ON ch.content_id = v.content_id
GROUP BY h.hashtag_id, h.hashtag_text, h.category
ORDER BY engagement_rank, h.hashtag_text
LIMIT 10;
