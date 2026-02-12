DROP TABLE pending_logins;

CREATE UNLOGGED TABLE pending_logins(
    token_id            UUID        PRIMARY KEY,
    expires             TIMESTAMPTZ,
    user_id             INTEGER     REFERENCES users(id) ON DELETE CASCADE,
    loopback_port       INTEGER     NOT NULL DEFAULT 0,
    oidc_client_type    SMALLINT,
    token_hash          BYTEA       NOT NULL,
    oidc_provider       TEXT        NOT NULL DEFAULT '',
    oidc_code_verifier  TEXT
);


---- create above / drop below ----

DROP TABLE pending_logins;

CREATE UNLOGGED TABLE pending_logins(
    token_id            UUID        PRIMARY KEY,
    expires             TIMESTAMPTZ,
    user_id             INTEGER     REFERENCES users(id) ON DELETE CASCADE,
    token_hash          BYTEA       NOT NULL,
    oidc_provider       TEXT,
    oidc_client_type    SMALLINT,
    oidc_code_verifier  TEXT,
    loopback_port       INTEGER     NOT NULL DEFAULT 0
);