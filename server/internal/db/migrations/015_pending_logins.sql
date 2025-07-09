CREATE UNLOGGED TABLE pending_logins(
  token             TEXT        PRIMARY KEY,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id           INTEGER     REFERENCES users(id) ON DELETE CASCADE,
  oidc_provider     TEXT,
  oidc_client_type  SMALLINT
);

---- create above / drop below ----

DROP TABLE pending_logins;
