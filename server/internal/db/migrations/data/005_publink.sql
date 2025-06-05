CREATE TABLE publinks(
  id              TEXT        PRIMARY KEY,
  created         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  root            UUID        NOT NULL REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  accessed        INT         NOT NULL DEFAULT 0,
  access_limit    INT         NOT NULL DEFAULT 0,
  password_hash   TEXT        NOT NULL DEFAULT '',
  expires         TIMESTAMP
);

CREATE INDEX publinks_by_root ON publinks(root);

---- create above / drop below ----

DROP INDEX IF EXISTS publinks_by_root;

DROP TABLE publinks;