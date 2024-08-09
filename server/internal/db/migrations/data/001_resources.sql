CREATE TABLE resources (
  id       uuid      PRIMARY KEY,
  parent   uuid      REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  name     TEXT      NOT NULL,
  dir      BOOLEAN   NOT NULL,
  created  TIMESTAMP NOT NULL,
  modified TIMESTAMP NOT NULL,
  deleted  TIMESTAMP,
  size     BIGINT,
  etag     TEXT
);

---- create above / drop below ----

DROP TABLE resources;