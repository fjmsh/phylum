CREATE FUNCTION readdir(resource_id UUID, min_depth INT, max_depth INT) RETURNS SETOF full_resource AS $$
  WITH RECURSIVE nodes(id, name, parent, dir, created, modified, content_length, content_type, content_sha256, depth) AS (
    SELECT r.id, r.name, r.parent, r.dir, r.created, r.modified, r.content_length, r.content_type, r.content_sha256, 0
      FROM resources r
      WHERE r.id = resource_id
    UNION ALL
      SELECT r.id, r.name, r.parent, r.dir, r.created, r.modified, r.content_length, r.content_type, r.content_sha256, n.depth + 1
        FROM resources r
        JOIN nodes n ON r.parent = n.id
        WHERE r.deleted IS NULL
        AND r.id != resource_id
        AND n.depth < max_depth
  ), resource_permissions(id, permissions) AS (
    SELECT p.resource_id, jsonb_object_agg(p.username, p.value) FROM permissions p WHERE p.value <> 0 GROUP BY p.resource_id
  ), resource_publinks(id, names) AS (
    SELECT l.root, jsonb_agg(l.name) FROM publinks l WHERE l.deleted IS NULL GROUP BY l.root
  )
  SELECT r.id, r.name, r.parent, r.dir, r.created, r.modified, NULL::TIMESTAMP AS deleted, r.content_length, r.content_type, r.content_sha256, p.permissions, l.names
    FROM nodes r
    LEFT JOIN resource_permissions p ON r.id = p.id
    LEFT JOIN resource_publinks l ON r.id = l.id
    WHERE depth >= min_depth;
$$ LANGUAGE SQL;

---- create above / drop below ----

DROP FUNCTION IF EXISTS readdir;