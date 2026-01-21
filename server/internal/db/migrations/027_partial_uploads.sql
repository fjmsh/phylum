CREATE TABLE partial_uploads(
    id          UUID        PRIMARY KEY,
    created     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    owner       INT         NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
    size        BIGINT      NOT NULL,
    uploaded    BIGINT      NOT NULL,
    sha256      TEXT        NOT NULL,
);


---- create above / drop below ----

DROP TABLE partial_uploads;
