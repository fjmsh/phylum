CREATE TABLE users(
  username      TEXT        PRIMARY KEY,
  created       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  display_name  TEXT        NOT NULL,
  password_hash TEXT        NOT NULL,
  deleted       TIMESTAMP,
  root          uuid        NOT NULL REFERENCES resources(id),
  home          uuid        NOT NULL REFERENCES resources(id),
  bookmarks     JSONB       NOT NULL DEFAULT '[]'
);

---- create above / drop below ----

DROP TABLE users;