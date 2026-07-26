-- Business question: Does reaction mix vary by discovery source?
-- Techniques: grouped counts and a partitioned window denominator.

WITH reaction_counts AS (
  SELECT
    device_source,
    reaction_type,
    COUNT(*) AS reaction_count
  FROM likes
  GROUP BY device_source, reaction_type
)
SELECT
  device_source,
  reaction_type,
  reaction_count,
  ROUND(
    100.0 * reaction_count
    / SUM(reaction_count) OVER (PARTITION BY device_source),
    2
  ) AS source_reaction_pct
FROM reaction_counts
ORDER BY device_source, reaction_count DESC, reaction_type;
