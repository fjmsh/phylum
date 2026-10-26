package core

import (
	"slices"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type ResourceAncestor struct {
	ID             uuid.UUID
	Name           string
	UserPermission ResourcePermission
}

func (f *FileSystem) scanResourceAncestor(row pgx.CollectableRow) (ResourceAncestor, error) {
	var a ResourceAncestor
	err := row.Scan(
		&a.ID,
		&a.Name,
		&a.UserPermission,
	)
	return a, err
}

const ancestorsQuery = `WITH RECURSIVE nodes(id, name, parent, userPermission) AS (
    SELECT r.id, r.name, r.parent, COALESCE(r.permissions[$2::INT]::INT, 0) as userPermission
        FROM resources r
        WHERE r.id = $1::UUID
    UNION ALL
        SELECT r.id, r.name, r.parent, COALESCE(r.permissions[$2::INT]::INT, 0) as userPermission
            FROM resources r
            JOIN nodes n ON r.id = n.parent
)
SELECT id, name, userPermission FROM nodes`

func (f *FileSystem) getAncestorsUnsafe(r Resource) ([]ResourceAncestor, error) {
	if rows, err := f.db.Query(ancestorsQuery, r.id, f.userID); err != nil {
		return nil, err
	} else if a, err := pgx.CollectRows(rows, f.scanResourceAncestor); err != nil {
		return nil, err
	} else {
		return a[1:], nil
	}
}

func (f *FileSystem) GetAncestors(r Resource) ([]ResourceAncestor, error) {
	if ancestors, err := f.getAncestorsUnsafe(r); err != nil {
		return nil, err
	} else {
		scopeMatch := f.allResourcesScope&ResourcePermissionRead == ResourcePermissionRead
		permissionMatch := f.userFilesPrivilege&ResourcePermissionRead == ResourcePermissionRead
		slices.Reverse(ancestors)
		start := len(ancestors)
		for i, a := range ancestors {
			scopeMatch = scopeMatch || (f.scopedResources[a.ID]&ResourcePermissionRead == ResourcePermissionRead)
			permissionMatch = permissionMatch || (a.UserPermission&ResourcePermissionRead == ResourcePermissionRead)
			if scopeMatch && permissionMatch {
				start = i
				break
			}
		}
		return ancestors[start:], nil
	}
}

func (f *FileSystem) GetPath(r Resource) (string, error) {
	if a, err := f.GetAncestors(r); err != nil {
		return "", err
	} else {
		if len(a) == 0 {
			path := ""
			if r.dir {
				path = "/"
			}
			if r.id != f.fsRoot {
				path = ":" + r.id.String() + path
			}
			return path, nil
		}
		b := strings.Builder{}
		if a[0].ID != f.fsRoot {
			b.WriteByte(byte(':'))
			b.WriteString(a[0].ID.String())
		}
		for _, p := range a[1:] {
			b.WriteByte(byte('/'))
			b.WriteString(p.Name)
		}
		b.WriteByte(byte('/'))
		b.WriteString(r.name)
		return b.String(), nil
	}
}
