CREATE TABLE trips (
                       id         BIGSERIAL    PRIMARY KEY,
                       user_id    BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                       title      VARCHAR(150) NOT NULL,
                       city       VARCHAR(100) NOT NULL,
                       country    VARCHAR(100) NOT NULL,
                       created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE trip_days (
                           id         BIGSERIAL PRIMARY KEY,
                           trip_id    BIGINT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
                           day_number INT       NOT NULL,
                           UNIQUE (trip_id, day_number)
);

CREATE TABLE trip_stops (
                            id          BIGSERIAL        PRIMARY KEY,
                            trip_day_id BIGINT           NOT NULL REFERENCES trip_days(id) ON DELETE CASCADE,
                            sort_order  INT              NOT NULL,
                            name        VARCHAR(200)     NOT NULL,
                            latitude    DOUBLE PRECISION,
                            longitude   DOUBLE PRECISION,
                            note        VARCHAR(500)
);

CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trip_days_trip_id ON trip_days(trip_id);
CREATE INDEX idx_trip_stops_day_id ON trip_stops(trip_day_id);