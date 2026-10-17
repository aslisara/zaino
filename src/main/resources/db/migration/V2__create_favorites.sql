CREATE TABLE favorites (
                           id         BIGSERIAL    PRIMARY KEY,
                           user_id    BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                           type       VARCHAR(20)  NOT NULL,
                           name       VARCHAR(200) NOT NULL,
                           city       VARCHAR(100) NOT NULL,
                           country    VARCHAR(100) NOT NULL,
                           created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
                           UNIQUE (user_id, type, name, city)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);