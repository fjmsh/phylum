-- name: GrantUserPermissionForResource :exec
UPDATE resources
SET
    grants[@username::text] = jsonb_build_object('p', @permission::INT, 't', EXTRACT(EPOCH FROM NOW())::INTEGER),
    modified = NOW()
WHERE id = @resource_id::uuid
RETURNING permissions;

-- name: RevokeUserPermissionForResource :exec
UPDATE resources
SET
    grants = grants - @username::TEXT,
    modified = NOW()
WHERE id = @resource_id::uuid
RETURNING permissions;