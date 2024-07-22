CREATE TABLE resources (
  id       uuid      PRIMARY KEY,
  parent   uuid      REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  name     TEXT      NOT NULL,
  dir      BOOLEAN   NOT NULL,
  created  TIMESTAMP NOT NULL,
  modified TIMESTAMP NOT NULL,
  deleted  TIMESTAMP,
  size     INT,
  etag     TEXT
  -- CONSTRAINT resource_parent FOREIGN KEY REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE;
);

CREATE UNIQUE INDEX unique_member_resource_name ON resources(parent, name) WHERE deleted IS NULL;

---- create above / drop below ----

DROP INDEX unique_member_resource_name

DROP TABLE resources