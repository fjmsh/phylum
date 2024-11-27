CREATE TABLE resources (
  id              uuid      PRIMARY KEY,
  name            TEXT      NOT NULL,
  parent          uuid      REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  dir             BOOLEAN   NOT NULL,
  created         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted         TIMESTAMP,
  content_size    BIGINT    NOT NULL DEFAULT 0,
  content_type    TEXT      NOT NULL DEFAULT '',
  content_sha256  TEXT      NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX unique_member_resource_name ON resources(parent, name) WHERE deleted IS NULL;


---- create above / drop below ----

DROP INDEX unique_member_resource_name;

DROP TABLE resources;
