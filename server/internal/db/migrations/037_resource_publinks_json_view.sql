CREATE VIEW resource_publinks_json AS
SELECT r.id, jsonb_agg(jsonb_build_object(
	'id',l.id,
	'expires',EXTRACT(EPOCH FROM l.expires)::integer,
	'protected',l.password_hash <> '',
	'access_limit',l.access_limit,
	'accessed',l.accessed
	)) AS publinks
FROM resources r
JOIN publinks l ON r.id = l.root
GROUP BY r.id;


---- create above / drop below ----

DROP VIEW resource_publinks_json;