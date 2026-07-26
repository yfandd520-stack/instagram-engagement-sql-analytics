-- Instagram Engagement Analytics
-- MySQL 8.0+

CREATE DATABASE IF NOT EXISTS instagram_engagement_analytics
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE instagram_engagement_analytics;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS content_hashtags;
DROP TABLE IF EXISTS view_logs;
DROP TABLE IF EXISTS likes;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS content;
DROP TABLE IF EXISTS hashtags;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  user_id INT NOT NULL,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL,
  registration_date DATE NOT NULL,
  account_type ENUM('personal', 'creator', 'business') NOT NULL,
  follower_count INT UNSIGNED NOT NULL DEFAULT 0,
  following_count INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id),
  CONSTRAINT uq_users_username UNIQUE (username),
  CONSTRAINT uq_users_email UNIQUE (email)
) ENGINE = InnoDB;

CREATE TABLE content (
  content_id INT NOT NULL,
  content_type ENUM('Reel', 'Post', 'Story') NOT NULL,
  upload_timestamp DATETIME NOT NULL,
  duration_seconds SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  caption VARCHAR(255) NOT NULL,
  visibility ENUM('public', 'friends', 'private') NOT NULL,
  user_id INT NOT NULL,
  PRIMARY KEY (content_id),
  KEY idx_content_user_uploaded (user_id, upload_timestamp),
  CONSTRAINT fk_content_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE sessions (
  session_id INT NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  device_os ENUM('iOS', 'Android') NOT NULL,
  device_type ENUM('Phone', 'Tablet') NOT NULL,
  session_duration INT UNSIGNED NOT NULL,
  user_id INT NOT NULL,
  PRIMARY KEY (session_id),
  KEY idx_sessions_user_start (user_id, start_time),
  CONSTRAINT chk_sessions_time_order CHECK (end_time >= start_time),
  CONSTRAINT fk_sessions_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE hashtags (
  hashtag_id INT NOT NULL,
  hashtag_text VARCHAR(50) NOT NULL,
  created_date DATE NOT NULL,
  usage_count INT UNSIGNED NOT NULL DEFAULT 0,
  trending_score DECIMAL(5,2) NOT NULL,
  category VARCHAR(50) NOT NULL,
  PRIMARY KEY (hashtag_id),
  CONSTRAINT uq_hashtags_text UNIQUE (hashtag_text),
  CONSTRAINT chk_hashtags_trending_score
    CHECK (trending_score BETWEEN 0 AND 100)
) ENGINE = InnoDB;

CREATE TABLE content_hashtags (
  content_id INT NOT NULL,
  hashtag_id INT NOT NULL,
  PRIMARY KEY (content_id, hashtag_id),
  KEY idx_content_hashtags_hashtag (hashtag_id, content_id),
  CONSTRAINT fk_content_hashtags_content
    FOREIGN KEY (content_id) REFERENCES content (content_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_content_hashtags_hashtag
    FOREIGN KEY (hashtag_id) REFERENCES hashtags (hashtag_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE likes (
  like_id INT NOT NULL,
  user_id INT NOT NULL,
  content_id INT NOT NULL,
  like_timestamp DATETIME NOT NULL,
  reaction_type ENUM('like', 'love') NOT NULL,
  device_source ENUM('feed', 'explore', 'profile') NOT NULL,
  PRIMARY KEY (like_id),
  CONSTRAINT uq_likes_user_content UNIQUE (user_id, content_id),
  KEY idx_likes_content_time (content_id, like_timestamp),
  CONSTRAINT fk_likes_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_likes_content
    FOREIGN KEY (content_id) REFERENCES content (content_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE comments (
  comment_id INT NOT NULL,
  user_id INT NOT NULL,
  content_id INT NOT NULL,
  comment_text VARCHAR(500) NOT NULL,
  comment_timestamp DATETIME NOT NULL,
  comment_length SMALLINT UNSIGNED NOT NULL,
  sentiment_score DECIMAL(4,3) NOT NULL,
  PRIMARY KEY (comment_id),
  KEY idx_comments_content_time (content_id, comment_timestamp),
  CONSTRAINT chk_comments_sentiment
    CHECK (sentiment_score BETWEEN -1 AND 1),
  CONSTRAINT fk_comments_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_comments_content
    FOREIGN KEY (content_id) REFERENCES content (content_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE view_logs (
  log_id INT NOT NULL,
  content_id INT NOT NULL,
  session_id INT NOT NULL,
  interaction_timestamp DATETIME NOT NULL,
  interaction_type ENUM('auto-play', 'click', 'scroll') NOT NULL,
  time_spent_seconds SMALLINT UNSIGNED NOT NULL,
  completion_rate DECIMAL(5,2) NOT NULL,
  PRIMARY KEY (log_id),
  KEY idx_view_logs_content_time (content_id, interaction_timestamp),
  KEY idx_view_logs_session_time (session_id, interaction_timestamp),
  CONSTRAINT chk_view_logs_completion
    CHECK (completion_rate BETWEEN 0 AND 100),
  CONSTRAINT fk_view_logs_content
    FOREIGN KEY (content_id) REFERENCES content (content_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_view_logs_session
    FOREIGN KEY (session_id) REFERENCES sessions (session_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;
