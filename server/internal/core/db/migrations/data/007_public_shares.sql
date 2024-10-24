CREATE TABLE public_shares(
  id              TEXT        PRIMARY KEY,
  created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted         TIMESTAMP,
  created_by      TEXT        NOT NULL REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE,
  root            UUID        NOT NULL REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  password_hash   TEXT,
  expires         TIMESTAMP,
  accesses_left   INT
);

---- create above / drop below ----

DROP TABLE public_shares;