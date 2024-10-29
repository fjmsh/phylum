CREATE TABLE publinks(
  id              SERIAL      PRIMARY KEY,
  name            TEXT        NOT NULL,
  created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted         TIMESTAMP,
  created_by      TEXT        NOT NULL REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE,
  root            UUID        NOT NULL REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  accessed        INT         NOT NULL DEFAULT 0,
  max_accesses    INT         NOT NULL DEFAULT 0,
  password_hash   TEXT        NOT NULL DEFAULT '',
  expires         TIMESTAMP
);

CREATE UNIQUE INDEX unique_publink ON publinks(name) WHERE deleted IS NULL;

CREATE INDEX publinks_by_root ON publinks(root, deleted);

CREATE INDEX publinks_by_creator ON publinks(created_by);

---- create above / drop below ----

DROP INDEX IF EXISTS publinks_by_creator;

DROP INDEX IF EXISTS publinks_by_root;

DROP INDEX IF EXISTS unique_publink;

DROP TABLE publinks;