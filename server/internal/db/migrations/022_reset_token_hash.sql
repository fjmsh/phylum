DROP TABLE reset_tokens;

CREATE UNLOGGED TABLE reset_tokens(
    user_id     INT         PRIMARY KEY REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    token_hash  BYTEA       NOT NULL,
    expires     TIMESTAMPTZ NOT NULL
);


---- create above / drop below ----

DROP TABLE reset_tokens;

CREATE TABLE reset_tokens(
    user_id     INT         PRIMARY KEY REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    token       TEXT        NOT NULL,
    expires     TIMESTAMPTZ NOT NULL
);