DROP TABLE api_keys;

CREATE TABLE api_keys(
    id          UUID        NOT NULL PRIMARY KEY,
    created     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires     TIMESTAMPTZ,
    user_id     INT         NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    hash        BYTEA       NOT NULL,
    description TEXT,
    scopes      TEXT[]      NOT NULL DEFAULT '{"*"}'
);


---- create above / drop below ----

DROP TABLE api_keys;

CREATE TABLE api_keys(
    key         TEXT        NOT NULL PRIMARY KEY,
    created     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires     TIMESTAMPTZ,
    user_id     INT         NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
    name        TEXT        NOT NULL,
    scopes      TEXT[]      NOT NULL DEFAULT '{"*"}'
);

CREATE UNIQUE INDEX unique_named_user_key ON api_keys(user_id, name);