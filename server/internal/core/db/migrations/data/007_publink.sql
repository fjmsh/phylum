CREATE TABLE publinks(
  id              SERIAL      PRIMARY KEY,
  name            TEXT        NOT NULL,
  created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted         TIMESTAMP,
  created_by      TEXT        NOT NULL REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE,
  root            UUID        NOT NULL REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  accessed        INT         NOT NULL DEFAULT 0,
  max_accesses    INT,
  password_hash   TEXT,
  expires         TIMESTAMP
);

CREATE UNIQUE INDEX unique_publink ON publinks(name) WHERE deleted IS NULL;
---- create above / drop below ----

DROP INDEX IF EXISTS unique_publink;

DROP TABLE publinks;