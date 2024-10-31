CREATE FUNCTION readdir(resource_id UUID, min_depth INT, max_depth INT) RETURNS SETOF publinked_resource AS $$
  WITH RECURSIVE nodes(id, permissions, name, parent, dir, created, modified, content_size, content_type, content_sha256, depth) AS (
    SELECT r.id, r.permissions, r.name, r.parent, r.dir, r.created, r.modified, r.content_size, r.content_type, r.content_sha256, 0
      FROM resources r
      WHERE r.id = resource_id
    UNION ALL
      SELECT r.id, r.permissions, r.name, r.parent, r.dir, r.created, r.modified, r.content_size, r.content_type, r.content_sha256, n.depth + 1
        FROM resources r
        JOIN nodes n ON r.parent = n.id
        WHERE r.deleted IS NULL
        AND r.id != resource_id
        AND n.depth < max_depth
  ), links(id, count) AS (
    SELECT root, count(p.id) FROM publinks p WHERE p.deleted IS NULL GROUP BY p.root
  )
  SELECT r.id, r.permissions, r.name, r.parent, r.dir, r.created, r.modified, NULL::TIMESTAMP AS deleted, r.content_size, r.content_type, r.content_sha256, COALESCE(l.count, 0)
    FROM nodes r
    LEFT JOIN links l ON r.id = l.id
    WHERE depth >= min_depth;
$$ LANGUAGE SQL;

---- create above / drop below ----

DROP FUNCTION IF EXISTS readdir;