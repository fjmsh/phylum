package fs

import (
	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func selectResourceTree(ds *goqu.SelectDataset, nodes exp.IdentifierExpression, id uuid.UUID, includeDeleted bool) *goqu.SelectDataset {
	resTable := goqu.T("resources").As("r")
	rec := pg.From(resTable).
		Select(resTable.Col("id"), resTable.Col("parent"), resTable.Col("deleted"), goqu.L("? + 1", goqu.I("n.depth"))).
		Join(nodes.As("n"), goqu.On(goqu.I("r.parent").Eq(goqu.I("n.id"))))

	if !includeDeleted {
		rec = rec.Where(
			goqu.Or(
				goqu.I("r.deleted").Eq(goqu.I("n.deleted")),
				goqu.And(
					goqu.I("r.deleted").IsNull(),
					goqu.I("n.deleted").IsNull(),
				)))
	}

	return ds.WithRecursive(nodes.GetTable()+"(id, parent, deleted, depth)",
		pg.From(resTable).
			Select(resTable.Col("id"), resTable.Col("parent"), resTable.Col("deleted"), goqu.L("0")).
			Where(goqu.I("r.id").Eq(id)).
			UnionAll(rec))
}

func (f filesystem) collectResource(rows pgx.Rows) (Resource, error) {
	if r, err := pgx.CollectExactlyOneRow(rows, f.scanResource); err == nil {
		return r, nil
	} else {
		if err == pgx.ErrNoRows {
			err = ErrResourceNotFound
		}
		return r, err
	}

}

func (f filesystem) scanResource(row pgx.CollectableRow) (Resource, error) {
	var r Resource
	err := row.Scan(
		&r.id,
		&r.name,
		&r.parentID,
		&r.dir,
		&r.created,
		&r.modified,
		&r.deleted,
		&r.contentLength,
		&r.contentType,
		&r.contentSHA256,
		&r.permissions,
		&r.grants,
	)
	if err != nil {
		return r, err
	}
	permission := Permission(0)
	if f.fullAccess {
		permission = -1
	} else if p, err := readPermissionFromJson(r.permissions, f.username); err != nil {
		return Resource{}, err
	} else {
		permission = p
	}
	if permission&PermissionRead == 0 {
		return Resource{}, ErrResourceNotFound
	}
	r.f = f
	r.userPermission = permission
	return r, err
}

func collectNonDirResourceIDs(rows pgx.Rows, e error) (total int, ids []uuid.UUID, err error) {
	if e != nil {
		return 0, nil, e
	}
	defer rows.Close()
	var id uuid.UUID
	var dir bool
	for rows.Next() {
		if err := rows.Scan(&id, &dir); err != nil {
			return total, nil, err
		}
		if !dir {
			ids = append(ids, id)
		}
		total++
	}
	err = rows.Err()
	return total, ids, err
}
