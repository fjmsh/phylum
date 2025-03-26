package fs

import (
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type ResourceAncestor struct {
	ID          uuid.UUID
	ParentID    uuid.UUID
	Name        string
	Permissions []byte
}

func (f filesystem) scanResourceAncestor(row pgx.CollectableRow) (ResourceAncestor, error) {
	var a ResourceAncestor
	err := row.Scan(
		&a.ID,
		&a.Name,
		&a.ParentID,
		&a.Permissions,
	)
	return a, err
}

const ancestorsQuery = `WITH RECURSIVE nodes(id, name, parent, permissions) AS (
    SELECT r.id, r.name, r.parent, r.permissions
        FROM resources r
        WHERE r.id = $1::UUID
    UNION ALL
        SELECT r.id, r.name, r.parent, r.permissions
            FROM resources r
            JOIN nodes n ON r.id = n.parent
)
SELECT id, name, parent, permissions FROM nodes`

func (r Resource) GetAncestors() ([]ResourceAncestor, error) {
	if rows, err := r.f.db.Query(r.f.ctx, ancestorsQuery, r.parentID); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, r.f.scanResourceAncestor)
	}
}

func (r Resource) GetPath() (string, error) {
	if a, err := r.GetAncestors(); err != nil {
		return "", err
	} else {
		if len(a) <= 1 {
			return "/", nil
		}
		b := strings.Builder{}
		for i := len(a) - 1; i >= 0; i-- {
			b.WriteString(a[i].Name)
			b.WriteByte(byte('/'))
		}
		b.Write([]byte(r.name))
		return b.String(), nil
	}
}
