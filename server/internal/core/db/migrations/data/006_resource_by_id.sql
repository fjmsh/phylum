-- sqlc has a hard time generating the correct code with functions returning types instead of tables
CREATE TABLE publinked_resource (
  publinks              INT NOT NULL DEFAULT 0
) INHERITS (resources);


CREATE FUNCTION resource_by_id(resource_id uuid) RETURNS SETOF publinked_resource AS $$
  WITH RECURSIVE nodes(id, permissions, name, parent, dir, created, modified, deleted, content_size, content_type, content_sha256) AS (
    SELECT r.id, r.permissions, r.name, r.parent, r.dir, r.created, r.modified, r.deleted, r.content_size, r.content_type, r.content_sha256
      FROM resources r
      WHERE r.id = resource_id
    UNION ALL
      SELECT r.id, r.permissions, r.name, r.parent, r.dir, r.created, r.modified, r.deleted, r.content_size, r.content_type, r.content_sha256
        FROM resources r
        JOIN nodes n ON r.id = n.parent
  ), links(id, count) AS (
    SELECT root, count(p.id) FROM publinks p WHERE p.deleted IS NULL GROUP BY p.root
  )
  SELECT r.id, r.permissions, r.name, r.parent, r.dir, r.created, r.modified, r.deleted, r.content_size, r.content_type, r.content_sha256, COALESCE(l.count, 0)
    FROM nodes r
    LEFT JOIN links l ON r.id = l.id;
$$ LANGUAGE SQL;

---- create above / drop below ----

DROP FUNCTION resource_by_id;

DROP TABLE publinked_resource;