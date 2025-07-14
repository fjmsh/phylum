DROP TABLE pending_logins;


CREATE UNLOGGED TABLE pending_logins(
    token_id            UUID        PRIMARY KEY,
    expires             TIMESTAMPTZ,
    user_id             INTEGER     REFERENCES users(id) ON DELETE CASCADE,
    token_hash          BYTEA       NOT NULL,
    oidc_provider       TEXT,
    oidc_client_type    SMALLINT,
    oidc_code_verifier  TEXT
);


---- create above / drop below ----

DROP TABLE pending_logins;

CREATE TABLE pending_logins(
    token               TEXT            PRIMARY KEY,
    user_id             INTEGER         REFERENCES users(id) ON DELETE CASCADE,
    oidc_provider       TEXT,
    oidc_client_type    SMALLINT,
    code_verifier       VARCHAR(128)    NOT NULL DEFAULT '';
    expires             TIMESTAMPTZ,
);