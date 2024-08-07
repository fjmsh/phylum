CREATE TABLE users(
    id            SERIAL PRIMARY KEY,
    username      TEXT NOT NULL UNIQUE,
    created       TIMESTAMP NOT NULL,
    modified      TIMESTAMP NOT NULL,
    display_name  TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    deleted       TIMESTAMP,
    root          uuid NOT NULL,
    home          uuid NOT NULL
);
CREATE TABLE resources (
  id       uuid      PRIMARY KEY,
  owner    INT       NOT NULL,
  parent   uuid      REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  name     TEXT      NOT NULL,
  dir      BOOLEAN   NOT NULL,
  created  TIMESTAMP NOT NULL,
  modified TIMESTAMP NOT NULL,
  deleted  TIMESTAMP,
  size     BIGINT,
  etag     TEXT
);

ALTER TABLE resources
  ADD CONSTRAINT resource_owner
  FOREIGN KEY (owner)
  REFERENCES users(id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE users
  ADD CONSTRAINT user_root
  FOREIGN KEY (root)
  REFERENCES resources(id)
  ON UPDATE RESTRICT
  DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE users
  ADD CONSTRAINT user_home
  FOREIGN KEY (home)
  REFERENCES resources(id)
  ON UPDATE RESTRICT
  DEFERRABLE INITIALLY DEFERRED;

---- create above / drop below ----

DROP TABLE users;

DROP TABLE resources;