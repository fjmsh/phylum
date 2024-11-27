-- sqlc has a hard time generating the correct code with functions returning types instead of tables
CREATE TABLE full_resource (
  permissions           JSONB,
  publinks              JSONB
) INHERITS (resources);


CREATE FUNCTION resource_by_id(resource_id uuid) RETURNS SETOF full_resource AS $$
  WITH RECURSIVE nodes(id, name, parent, dir, created, modified, deleted, content_size, content_type, content_sha256) AS (
    SELECT r.id, r.name, r.parent, r.dir, r.created, r.modified, r.deleted, r.content_size, r.content_type, r.content_sha256
      FROM resources r
      WHERE r.id = resource_id
    UNION ALL
      SELECT r.id, r.name, r.parent, r.dir, r.created, r.modified, r.deleted, r.content_size, r.content_type, r.content_sha256
        FROM resources r
        JOIN nodes n ON r.id = n.parent
  ), resource_permissions(id, permissions) AS (
    SELECT p.resource_id, jsonb_object_agg(p.username, p.value) FROM permissions p WHERE p.value <> 0 GROUP BY p.resource_id
  ), resource_publinks(id, names) AS (
    SELECT l.root, jsonb_agg(l.name) FROM publinks l WHERE l.deleted IS NULL GROUP BY l.root
  )
  SELECT r.id, r.name, r.parent, r.dir, r.created, r.modified, r.deleted, r.content_size, r.content_type, r.content_sha256, p.permissions, l.names
    FROM nodes r
    LEFT JOIN resource_permissions p ON r.id = p.id
    LEFT JOIN resource_publinks l ON r.id = l.id;
$$ LANGUAGE SQL;

---- create above / drop below ----

DROP FUNCTION resource_by_id;

DROP TABLE full_resource;