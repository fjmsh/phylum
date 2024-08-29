CREATE TABLE resources (
  id            uuid      PRIMARY KEY,
  parent        uuid      REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  name          TEXT      NOT NULL,
  dir           BOOLEAN   NOT NULL,
  created       TIMESTAMP NOT NULL,
  modified      TIMESTAMP NOT NULL,
  deleted       TIMESTAMP,
  size          BIGINT,
  sha256sum     TEXT
);

CREATE UNIQUE INDEX unique_member_resource_name ON resources(parent, name) WHERE deleted IS NULL;

---- create above / drop below ----

DROP TABLE resources;