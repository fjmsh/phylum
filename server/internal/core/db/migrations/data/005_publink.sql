CREATE TABLE publinks(
  id              TEXT        PRIMARY KEY,
  created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted         TIMESTAMP,
  created_by      TEXT        NOT NULL REFERENCES users(username) ON UPDATE CASCADE ON DELETE CASCADE,
  root            UUID        NOT NULL REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  accessed        INT         NOT NULL DEFAULT 0,
  max_accesses    INT         NOT NULL DEFAULT 0,
  password_hash   TEXT        NOT NULL DEFAULT '',
  expires         TIMESTAMP
);

CREATE INDEX publinks_by_root ON publinks(root, deleted);

CREATE INDEX publinks_by_creator ON publinks(created_by);

---- create above / drop below ----

DROP INDEX IF EXISTS publinks_by_creator;

DROP INDEX IF EXISTS publinks_by_root;

DROP TABLE publinks;