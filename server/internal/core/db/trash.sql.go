package db

import (
	"context"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var p = goqu.New("postgres", nil)

const emptyTrash = `DELETE FROM resources
    WHERE deleted IS NOT NULL
    AND CASE
        WHEN $1::TEXT IS NULL THEN TRUE
        ELSE permissions[$1::TEXT]::integer & 32 <> 0 END
    RETURNING id, dir
`

func (q *Queries) EmptyTrash(ctx context.Context, username pgtype.Text) (count int, ids []uuid.UUID, err error) {
	return collectDeletedRows(q.db.Query(ctx, emptyTrash, username))
}

func selectDescendentsCTE(id uuid.UUID, includeDeleted bool) (exp.AliasedExpression, *goqu.SelectDataset) {
	resTable := goqu.T("resources").As("r")
	rec := p.From(resTable).
		Select(resTable.Col("id"), resTable.Col("parent"), resTable.Col("deleted"), goqu.L("? + 1", goqu.I("n.depth"))).
		Join(goqu.T("nodes").As("n"), goqu.On(goqu.I("r.parent").Eq(goqu.I("n.id"))))

	if !includeDeleted {
		rec = rec.Where(
			goqu.Or(
				goqu.I("r.deleted").Eq(goqu.I("n.deleted")),
				goqu.And(
					goqu.I("r.deleted").IsNull(),
					goqu.I("n.deleted").IsNull(),
				)))
	}

	return resTable, p.From(resTable).WithRecursive("nodes(id, parent, deleted, depth)",
		p.From(resTable).
			Select(resTable.Col("id"), resTable.Col("parent"), resTable.Col("deleted"), goqu.L("0")).
			Where(goqu.I("r.id").Eq(id)).
			UnionAll(rec))
}

func (q *Queries) Delete(ctx context.Context, id uuid.UUID, softDelete, excludeRoot bool) (int, []uuid.UUID, error) {
	table, exp := selectDescendentsCTE(id, !softDelete)

	idSelect := p.From("nodes").Select("id")
	if excludeRoot {
		idSelect = idSelect.Where(goqu.C("depth").Gt(0))
	}
	exp = exp.Where(table.Col("id").Eq(idSelect))

	// table
	var query string
	var params []interface{}
	if softDelete {
		query, params, _ = exp.
			Update().
			Set(
				goqu.Record{
					"modified": goqu.L("NOW()"),
					"deleted":  goqu.L("NOW()"),
				}).
			Returning(table.Col("id"), table.Col("dir")).
			ToSQL()
	} else {
		query, params, _ = exp.
			Delete().
			Returning(table.Col("id"), table.Col("dir")).
			ToSQL()
	}

	return collectDeletedRows(q.db.Query(ctx, query, params...))
}

func collectDeletedRows(rows pgx.Rows, e error) (count int, ids []uuid.UUID, err error) {
	if e != nil {
		return 0, nil, e
	}
	defer rows.Close()
	var id uuid.UUID
	var dir bool
	for rows.Next() {
		if err := rows.Scan(&id, &dir); err != nil {
			return count, nil, err
		}
		if !dir {
			ids = append(ids, id)
		}
		count++
	}
	err = rows.Err()
	return count, ids, err
}

func (q *Queries) RestoreDeleted(ctx context.Context, id uuid.UUID) ([]int64, error) {
	table, exp := selectDescendentsCTE(id, false)

	idSelect := p.From("nodes").Select("id")
	exp = exp.Where(table.Col("id").Eq(idSelect))

	// table
	var query string
	var params []interface{}
	query, params, _ = exp.
		Update().
		Set(
			goqu.Record{
				"modified": goqu.L("NOW()"),
				"deleted":  nil,
			}).
		Returning(table.Col("content_length")).
		ToSQL()

	rows, err := q.db.Query(ctx, query, params...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []int64
	for rows.Next() {
		var content_length int64
		if err := rows.Scan(&content_length); err != nil {
			return nil, err
		}
		items = append(items, content_length)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

func (q *Queries) TrashCompact(ctx context.Context, t pgtype.Timestamp) (int, uuid.UUIDs, error) {
	return collectDeletedRows(q.db.Query(ctx, "DELETE FROM resources WHERE deleted < $1::TIMESTAMP RETURNING id, dir", t))
}

const trashList = `-- name: TrashList :many
SELECT id, name, parent, dir, created, modified, deleted, content_length, content_type, content_sha256, permissions, grants FROM resources
    WHERE CASE
        WHEN $1::TIMESTAMP IS NULL THEN deleted IS NOT NULL
        ELSE deleted < $1::TIMESTAMP OR (deleted = $1::TIMESTAMP AND id < $2::UUID) END
    AND CASE
        WHEN $3::TEXT IS NULL THEN TRUE
        ELSE permissions[$3::TEXT]::integer <> 0 END
    ORDER BY deleted DESC, id DESC
    LIMIT $4::INTEGER
`

type TrashListParams struct {
	LastTimestamp pgtype.Timestamp
	LastID        uuid.UUID
	Username      pgtype.Text
	N             int32
}

func (q *Queries) TrashList(ctx context.Context, arg TrashListParams) ([]Resource, error) {
	rows, err := q.db.Query(ctx, trashList,
		arg.LastTimestamp,
		arg.LastID,
		arg.Username,
		arg.N,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []Resource
	for rows.Next() {
		var i Resource
		if err := rows.Scan(
			&i.ID,
			&i.Name,
			&i.Parent,
			&i.Dir,
			&i.Created,
			&i.Modified,
			&i.Deleted,
			&i.ContentLength,
			&i.ContentType,
			&i.ContentSha256,
			&i.Permissions,
			&i.Grants,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

func (q *Queries) TrashSummary(ctx context.Context, username pgtype.Text) (int, int, error) {
	var whereCond exp.Expression = goqu.C("deleted").IsNotNull()
	if username.Valid {
		whereCond = goqu.And(whereCond, goqu.L("permissions[?]::INTEGER <> 0", username.String))
	}
	exp := p.
		From("resources").
		Select(
			goqu.COALESCE(goqu.SUM("content_length"), 0),
			goqu.COUNT("*")).
		Where(whereCond)

	query, args, _ := exp.ToSQL()
	row := q.db.QueryRow(ctx, query, args...)
	var size int
	var items int
	err := row.Scan(&size, &items)
	return items, size, err
}
