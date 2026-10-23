CREATE VIEW resource_ancestors AS
WITH RECURSIVE nodes(id, parent) AS (
    SELECT id, parent FROM resources
    UNION ALL
    SELECT n.id, r.parent
        FROM resources r
        JOIN nodes n ON r.id = n.parent
) SELECT id, array_agg(parent) AS ancestors
    FROM nodes
    WHERE parent IS NOT NULL
    GROUP BY id;


---- create above / drop below ----

DROP VIEW resource_ancestors;