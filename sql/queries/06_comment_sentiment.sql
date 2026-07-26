-- Business question: Which content receives the strongest comment sentiment?
-- Techniques: aggregation, CASE expression, HAVING, window ranking.

WITH comment_summary AS (
  SELECT
    c.content_id,
    c.content_type,
    c.caption,
    COUNT(cm.comment_id) AS comment_count,
    ROUND(AVG(cm.sentiment_score), 3) AS avg_sentiment,
    SUM(CASE WHEN cm.sentiment_score < 0 THEN 1 ELSE 0 END)
      AS negative_comments
  FROM content AS c
  JOIN comments AS cm ON c.content_id = cm.content_id
  GROUP BY c.content_id, c.content_type, c.caption
  HAVING COUNT(cm.comment_id) >= 2
)
SELECT
  DENSE_RANK() OVER (
    ORDER BY avg_sentiment DESC, comment_count DESC
  ) AS sentiment_rank,
  content_id,
  content_type,
  caption,
  comment_count,
  avg_sentiment,
  negative_comments
FROM comment_summary
ORDER BY sentiment_rank, content_id;
