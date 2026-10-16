CREATE TABLE users (
                       id            BIGSERIAL    PRIMARY KEY,
                       email         VARCHAR(255) NOT NULL UNIQUE,
                       password_hash VARCHAR(100) NOT NULL,
                       display_name  VARCHAR(80),
                       created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);