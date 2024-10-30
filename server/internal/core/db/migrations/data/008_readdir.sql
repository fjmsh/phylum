CREATE FUNCTION readdir(resource_id UUID, inherited_permissions JSONB, path TEXT, username TEXT, min_depth INT, max_depth INT) RETURNS SETOF resource_result AS $$
  WITH RECURSIVE nodes(id, permissions, name, parent, dir, created, modified, content_size, content_type, content_sha256, inherited_permissions, path, depth) AS (
    SELECT r.id,
      r.permissions,
      r.name,
      r.parent,
      r.dir,
      r.created,
      r.modified,
      r.content_size,
      r.content_type,
      r.content_sha256,
      COALESCE(inherited_permissions, '{}'),
      path,
      0
    FROM resources r
    WHERE r.id = resource_id
    UNION ALL
      SELECT
        r.id,
        r.permissions,
        r.name,
        r.parent,
        r.dir,
        r.created,
        r.modified,
        r.content_size,
        r.content_type,
        r.content_sha256,
        jsonb_bitwise_or(n.permissions, n.inherited_permissions),
        CONCAT(CASE n.path WHEN '/' THEN '' ELSE n.path END, '/', r.name),
        n.depth + 1
      FROM resources r JOIN nodes n on r.parent = n.id
      WHERE r.deleted IS NULL
      AND r.id != resource_id
      AND n.depth < max_depth
  ), links(id, count) AS (
    SELECT root, count(p.id) FROM publinks p WHERE p.deleted IS NULL GROUP BY p.root
  )
  SELECT
    n.id,
    n.permissions,
    n.name,
    n.parent,
    n.dir,
    n.created,
    n.modified,
    NULL::TIMESTAMP AS deleted,
    n.content_size,
    n.content_type,
    n.content_sha256,
    n.inherited_permissions,
    CASE username WHEN '' THEN 0 ELSE COALESCE((jsonb_bitwise_or(n.permissions, n.inherited_permissions)->(username))::int, 0)::int END AS user_permission,
    TRUE AS found,
    n.path AS path,
    COALESCE(l.count, 0) AS publinks
  FROM nodes n 
  LEFT JOIN links l ON n.id = l.id
  WHERE depth >= min_depth;
$$ LANGUAGE SQL;

---- create above / drop below ----

DROP FUNCTION IF EXISTS readdir;