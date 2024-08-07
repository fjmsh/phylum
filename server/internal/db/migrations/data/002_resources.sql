CREATE TABLE resources (
  id       uuid      PRIMARY KEY,
  owner    INT       NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  parent   uuid      NOT NULL REFERENCES resources(id) ON UPDATE CASCADE ON DELETE CASCADE,
  name     TEXT      NOT NULL,
  dir      BOOLEAN   NOT NULL,
  created  TIMESTAMP NOT NULL,
  modified TIMESTAMP NOT NULL,
  deleted  TIMESTAMP,
  size     BIGINT,
  etag     TEXT
);

INSERT INTO resources(
SELECT '00000000-0000-0000-0000-000000000000',
    id, 
  '00000000-0000-0000-0000-000000000000',
  'root',
  true,
  NOW(),
  NOW(),
  NULL,
  0,
  ''
FROM users where username = 'phylum');

CREATE UNIQUE INDEX unique_member_resource_name ON resources(parent, name) WHERE deleted IS NULL;

---- create above / drop below ----

DROP INDEX unique_member_resource_name;

DROP TABLE resources;