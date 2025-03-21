package db

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

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

func selectDescendentsCTE(includeDeleted bool) string {
	cte := `WITH RECURSIVE nodes(id, parent, deleted, depth) AS (
	SELECT r.id, r.parent, r.deleted, 0
		FROM resources r
		WHERE r.id = $1::UUID
	UNION ALL
	SELECT r.id, r.parent, r.deleted, n.depth+1
		FROM resources r
		JOIN nodes n ON r.parent = n.id
`

	var where []string
	if !includeDeleted {
		where = append(where, "r.deleted IS NOT DISTINCT FROM n.deleted")
	}

	if where != nil {
		cte += "WHERE " + strings.Join(where, "\nAND ")
	}

	cte += ")\n"

	return cte

}

func (q *Queries) Delete(ctx context.Context, id uuid.UUID, softDelete, preserveRoot bool) (count int, ids []uuid.UUID, err error) {
	query := selectDescendentsCTE(!softDelete)
	if softDelete {
		query += "UPDATE resources SET modified = NOW(), deleted = NOW()\n"
	} else {
		query += "DELETE FROM resources\n"
	}
	if preserveRoot {
		query += "WHERE id IN (SELECT id FROM nodes WHERE depth > 0)\n"
	} else {
		query += "WHERE id IN (SELECT id FROM nodes)\n"
	}

	query += "RETURNING id, dir"
	return collectDeletedRows(q.db.Query(ctx, query, id))
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

const restoreDeleted = `-- name: RestoreDeleted :many
WITH RECURSIVE nodes(id, parent, ts) AS (
    SELECT r.id, r.parent, r.deleted
        FROM resources r
        WHERE r.id = $1::UUID
        AND CASE
            WHEN $2::TEXT IS NULL THEN TRUE
            ELSE permissions[$2::TEXT]::integer <> 0 END
    UNION ALL
        SELECT r.id, r.parent, n.ts
            FROM resources r
            JOIN nodes n ON r.parent = n.id
            WHERE r.deleted = n.ts
)
UPDATE resources
    SET modified = NOW(), deleted = NULL
    FROM nodes
    WHERE resources.id = nodes.id
    RETURNING resources.content_length
`

type RestoreDeletedParams struct {
	ResourceID uuid.UUID
	Username   pgtype.Text
}

func (q *Queries) RestoreDeleted(ctx context.Context, arg RestoreDeletedParams) ([]int64, error) {
	rows, err := q.db.Query(ctx, restoreDeleted, arg.ResourceID, arg.Username)
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

const trashCompact = `-- name: TrashCompact :many
DELETE FROM resources WHERE deleted < $1::TIMESTAMP RETURNING id, dir
`

type TrashCompactRow struct {
	ID  uuid.UUID
	Dir bool
}

func (q *Queries) TrashCompact(ctx context.Context, t pgtype.Timestamp) ([]TrashCompactRow, error) {
	rows, err := q.db.Query(ctx, trashCompact, t)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []TrashCompactRow
	for rows.Next() {
		var i TrashCompactRow
		if err := rows.Scan(&i.ID, &i.Dir); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
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

const trashSummary = `-- name: TrashSummary :one
SELECT COALESCE(SUM(content_length), 0)::INTEGER AS size, COUNT(*) AS items
    FROM resources
    WHERE deleted IS NOT NULL
    AND CASE
        WHEN $1::TEXT IS NULL THEN TRUE
        ELSE permissions[$1::TEXT]::integer <> 0 END
`

type TrashSummaryRow struct {
	Size  int32
	Items int64
}

func (q *Queries) TrashSummary(ctx context.Context, username pgtype.Text) (TrashSummaryRow, error) {
	row := q.db.QueryRow(ctx, trashSummary, username)
	var i TrashSummaryRow
	err := row.Scan(&i.Size, &i.Items)
	return i, err
}
