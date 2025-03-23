package fs

import (
	"encoding/json"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	return f.resourceFromResult(f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: &f.rootID, Path: path}))
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	const query = "SELECT * FROM resources WHERE id = $1::UUID"
	if rows, err := f.db.Query(f.ctx, query, id); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows)
	}
}

func (f filesystem) ChildResourceByName(parentID uuid.UUID, name string) (Resource, error) {
	const query = "SELECT * FROM resources WHERE parent = $1::UUID AND name = $2::TEXT AND deleted IS NULL"
	if rows, err := f.db.Query(f.ctx, query, parentID, name); err != nil {
		return Resource{}, err
	} else {
		return f.collectResource(rows)
	}
}

func (f filesystem) resourceFromResult(r db.Resource, err error) (Resource, error) {
	if err == pgx.ErrNoRows {
		err = ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}
	permission := Permission(0)
	if f.fullAccess {
		permission = -1
	} else if p, err := readPermissionFromJson(r.Permissions, f.username); err != nil {
		return Resource{}, err
	} else {
		permission = p
	}
	if permission&PermissionRead == 0 {
		return Resource{}, ErrResourceNotFound
	}
	res := ResourceFromDB(r)
	res.f = f
	res.userPermission = permission
	return res, nil
}

func readPermissionFromJson(j []byte, username string) (Permission, error) {
	if j == nil {
		return PermissionNone, nil
	}
	p := make(map[string]Permission)
	err := json.Unmarshal(j, &p)
	if err != nil {
		return PermissionNone, err
	}
	if p, ok := p[username]; ok {
		return p, nil
	}
	return PermissionNone, nil
}

func (f filesystem) ResourceByPathOrUUID(pathOrUUID string) (Resource, error) {
	if pathOrUUID == "" {
		return Resource{}, ErrResourcePathInvalid
	}
	if pathOrUUID[0] == '/' {
		return f.ResourceByPath(pathOrUUID)
	}
	if id, err := uuid.Parse(pathOrUUID); err != nil {
		return Resource{}, err
	} else {
		return f.ResourceByID(id)
	}
}
