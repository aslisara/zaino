CREATE TABLE ai_usage (
    user_id    BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    usage_date DATE   NOT NULL,
    call_count INT    NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, usage_date)
);
