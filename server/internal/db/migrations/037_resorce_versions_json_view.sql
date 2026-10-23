CREATE VIEW resource_versions_json AS
SELECT r.id, jsonb_agg(jsonb_build_object(
	'id',v.id,
	'created',EXTRACT(EPOCH FROM v.created)::integer,
	'deleted',EXTRACT(EPOCH FROM v.deleted)::integer,
	'mime_type',v.mime_type,
	'size',v.size,
	'sha256',v.sha256,
	'imgres',v.imgres,
	'pending',v.pending
	) ORDER BY v.created DESC) AS versions
FROM resources r
JOIN resource_versions v ON r.id = v.resource_id
GROUP BY r.id;


---- create above / drop below ----

DROP VIEW resource_versions_json;