package fs

import (
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type ResourceAncestor struct {
	ID             uuid.UUID
	Name           string
	UserPermission Permission
}

func (f filesystem) scanResourceAncestor(row pgx.CollectableRow) (ResourceAncestor, error) {
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
			WHERE r.permissions[$2::INT]::INT <> 0
			OR $3::BOOLEAN
)
SELECT id, name, userPermission FROM nodes`

func (f filesystem) GetAncestors(r Resource) ([]ResourceAncestor, error) {
	if rows, err := f.db.Query(ancestorsQuery, r.id, f.userID, f.fullAccess); err != nil {
		return nil, err
	} else if a, err := pgx.CollectRows(rows, f.scanResourceAncestor); err != nil {
		return nil, err
	} else {
		return a[1:], nil
	}
}

func (f filesystem) GetPath(r Resource) (string, error) {
	if a, err := f.GetAncestors(r); err != nil {
		return "", err
	} else {
		if len(a) < 1 {
			return "/", nil
		}
		b := strings.Builder{}
		for i := len(a) - 1; i >= 0; i-- {
			// Don't write the name of the root resource
			if b.Len() != 0 {
				b.WriteString(a[i].Name)
			}
			b.WriteByte(byte('/'))
		}
		b.Write([]byte(r.name))
		return b.String(), nil
	}
}
