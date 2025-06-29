CREATE UNLOGGED TABLE openid_sessions(
  id            TEXT        PRIMARY KEY,
  provider      TEXT        NOT NULL,
  client_type   SMALLINT    NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id       INTEGER     REFERENCES users(id) ON DELETE CASCADE
);

---- create above / drop below ----


DROP TABLE openid_sessions;
