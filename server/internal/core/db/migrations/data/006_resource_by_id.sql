-- sqlc has a hard time generating the correct code with functions returning types instead of tables
CREATE TABLE resource_result (
  inherited_permissions JSONB NOT NULL DEFAULT '{}',
  user_permission       INT NOT NULL,
  found                 BOOLEAN NOT NULL,
  path                  TEXT NOT NULL,
  publinks              INT NOT NULL DEFAULT 0
) INHERITS (resources);

CREATE OR REPLACE FUNCTION jsonb_bitwise_or(a JSONB, b JSONB)
RETURNS JSONB LANGUAGE SQL AS $$
    SELECT 
        jsonb_object_agg(
            COALESCE(ka, kb), 
            CASE
                WHEN va ISNULL THEN vb::integer 
                WHEN vb ISNULL THEN va::integer 
                ELSE va::integer | vb::integer 
            END
        )
    FROM jsonb_each(a) e1(ka, va)
    FULL JOIN jsonb_each(b) e2(kb, vb) ON ka = kb
$$;

CREATE AGGREGATE agg_jsonb_bitwise_or(JSONB) (
    SFUNC = jsonb_bitwise_or,
    STYPE = JSONB,
    INITCOND = '{}'
);

CREATE FUNCTION resource_by_id(resource_id uuid, root uuid, username text) RETURNS resource_result AS $$
  WITH RECURSIVE nodes(resid, id, parent, inherited_permissions, name, path, found) AS (
    SELECT resource_id, r.id, r.parent, '{}'::jsonb, r.name, ''::text,
        CASE
          WHEN r.id = root THEN true
          ELSE false
        END
      FROM resources r
      WHERE r.id = resource_id
    UNION ALL
      SELECT n.resid, r.id, r.parent, jsonb_bitwise_or(r.permissions, n.inherited_permissions), r.name,
        CASE 
          WHEN n.found THEN n.path
          WHEN n.path = '' THEN n.name
          ELSE concat(n.name, '/', n.path)
        END,
        CASE
          WHEN r.id = root THEN true
          ELSE n.found
        END
      FROM resources r
      JOIN nodes n
      ON r.id = n.parent
  ), links(id, count) AS (
    SELECT root, count(p.id) FROM publinks p WHERE p.deleted IS NULL GROUP BY p.root
  )
  SELECT
    resid AS id,
    r.permissions,
    r.name,
    r.parent,
    r.dir,
    r.created,
    r.modified,
    r.deleted,
    r.content_size,
    r.content_type,
    r.content_sha256,
    n.inherited_permissions,
    COALESCE((jsonb_bitwise_or(r.permissions, n.inherited_permissions)->(username))::int, 0)::int AS user_permission,
    n.found,
    concat('/', n.path)::text AS path,
    COALESCE(l.count, 0)
  FROM nodes n
  JOIN resources r
    ON r.id = n.resid
  LEFT JOIN links l
    ON r.id = l.id
  WHERE n.parent IS NULL;
$$ LANGUAGE SQL;

---- create above / drop below ----

DROP AGGREGATE agg_jsonb_bitwise_or(JSONB);

DROP FUNCTION jsonb_bitwise_or;

DROP FUNCTION resource_by_id;

DROP TABLE resource_result;