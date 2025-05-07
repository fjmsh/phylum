CREATE TABLE users(
  username      TEXT        PRIMARY KEY,
  created       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted       TIMESTAMP,
  display_name  TEXT        NOT NULL,
  password_hash TEXT        NOT NULL,
  home          uuid        REFERENCES resources(id),
  permissions   INTEGER     NOT NULL DEFAULT 0
);

---- create above / drop below ----

DROP TABLE users;