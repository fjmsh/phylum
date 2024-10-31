CREATE FUNCTION resource_id_by_path(path text, root uuid) RETURNS uuid AS $$
  WITH RECURSIVE nodes(id, parent, search, depth) AS (
    SELECT r.id, r.parent, array_remove(string_to_array(path, '/', NULL), ''), 0
    FROM resources r
    WHERE r.id = root OR (r.parent IS NULL AND root IS NULL)
  UNION ALL
    SELECT r.id, r.parent, n.search, n.depth + 1
    FROM resources r
    JOIN nodes n ON r.parent = n.id
    WHERE deleted IS NULL
      AND r.name = n.search[n.depth + 1]
  )
  SELECT id FROM nodes WHERE cardinality(search) = depth;
$$ LANGUAGE sql;

CREATE FUNCTION resource_by_path(path text, root uuid) RETURNS SETOF publinked_resource AS $$
  SELECT * FROM resource_by_id(resource_id_by_path(path, root));
$$ LANGUAGE SQL;

---- create above / drop below ----

DROP FUNCTION resource_by_path;

DROP FUNCTION resource_id_by_path;