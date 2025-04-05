CREATE VIEW linked_resources AS
    SELECT r.*, (SELECT jsonb_agg(l.name) FROM publinks l WHERE l.root = r.id AND l.deleted IS NULL) AS links
    FROM resources r;

---- create above / drop below ----

DROP VIEW linked_resources;