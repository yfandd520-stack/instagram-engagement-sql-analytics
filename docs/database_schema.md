# Database Schema

## Design principles

The database uses eight normalized MySQL tables to separate user profiles, content, sessions, taxonomies, and interaction events. Surrogate integer keys identify each entity or event. Foreign keys preserve referential integrity, and the `content_hashtags` junction table resolves the many-to-many relationship between content and hashtags.

The schema is designed for analytical questions at four grains:

- one row per user or content item;
- one row per app session;
- one row per interaction event, such as a like, comment, or view;
- one row per content-hashtag assignment.

## Table summary

| Table | Grain | Primary key | Foreign keys | Rows | Purpose |
|---|---|---|---|---:|---|
| `users` | One row per user | `user_id` | - | 10 | Stores account identity, type, registration date, and follower metrics. |
| `content` | One row per content item | `content_id` | `user_id` | 15 | Stores Reels, Posts, and Stories created by users. |
| `sessions` | One row per app session | `session_id` | `user_id` | 12 | Captures session timing, device, operating system, and duration. |
| `hashtags` | One row per hashtag | `hashtag_id` | - | 12 | Stores hashtag category, usage, and trending metadata. |
| `content_hashtags` | One row per content-hashtag assignment | `(content_id, hashtag_id)` | `content_id`, `hashtag_id` | 34 | Implements the many-to-many content-tag relationship. |
| `likes` | One row per user-content reaction | `like_id` | `user_id`, `content_id` | 55 | Records reaction type, source, and timestamp. |
| `comments` | One row per comment | `comment_id` | `user_id`, `content_id` | 30 | Stores comment text, length, timestamp, and sentiment score. |
| `view_logs` | One row per content view event | `log_id` | `content_id`, `session_id` | 50 | Measures interaction type, time spent, and completion rate. |

## Relationships

| Parent | Child | Cardinality | Meaning |
|---|---|---|---|
| `users` | `content` | 1:M | A user can publish multiple content items. |
| `users` | `sessions` | 1:M | A user can open multiple app sessions. |
| `content` | `content_hashtags` | 1:M | A content item can receive multiple hashtags. |
| `hashtags` | `content_hashtags` | 1:M | A hashtag can be assigned to multiple content items. |
| `users` | `likes` | 1:M | A user can react to multiple content items. |
| `content` | `likes` | 1:M | A content item can receive multiple reactions. |
| `users` | `comments` | 1:M | A user can write multiple comments. |
| `content` | `comments` | 1:M | A content item can receive multiple comments. |
| `content` | `view_logs` | 1:M | A content item can generate multiple view events. |
| `sessions` | `view_logs` | 1:M | A session can contain multiple view events. |

## Integrity and performance controls

- Primary keys enforce unique entity and event identifiers.
- Unique constraints prevent duplicate usernames, emails, hashtag text, and duplicate user-content likes.
- Foreign keys use `RESTRICT` for parent entities and `CASCADE` for dependent interaction rows.
- `CHECK` constraints validate session time order, comment sentiment, hashtag trending score, and completion rate.
- Composite indexes support common analytical joins and time-based filters.
- Event tables are aggregated before multi-event joins to prevent join multiplication.

The executable definition is available in [`sql/00_schema.sql`](../sql/00_schema.sql).
