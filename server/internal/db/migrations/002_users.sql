CREATE TABLE users(
  id            INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted       TIMESTAMP,
  email         TEXT        NOT NULL UNIQUE,
  name          TEXT        NOT NULL,
  password_hash TEXT        NOT NULL,
  home          uuid        REFERENCES resources(id),
  permissions   INTEGER     NOT NULL DEFAULT 0,
  CONSTRAINT    valid_email CHECK (email ~* '^[a-zA-Z0-9_+&*-]+(?:\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$')
);

---- create above / drop below ----

DROP TABLE users;