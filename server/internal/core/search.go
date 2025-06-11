package core

import (
	"strings"

	"github.com/jackc/pgx/v5"
)

func (f filesystem) Search(query string, includeDeleted bool) ([]Resource, error) {
	qb := strings.Builder{}
	qb.WriteString(fullResourceQuery)
	qb.WriteString("WHERE f_prepare_search(r.name) %> @query::TEXT")
	if !includeDeleted {
		qb.WriteString("\nAND r.deleted IS NULL")
	}
	if f.user.Permissions&PermissionFilesAll == 0 {
		qb.WriteString("\nAND r.permissions[@user_id::INT]::INTEGER <> 0")
	}
	qb.WriteString("\nORDER BY word_similarity(f_prepare_search(r.name), @query::TEXT) DESC")

	args := pgx.NamedArgs{
		"query":   strings.ToLower(query),
		"user_id": f.user.ID,
	}

	if rows, err := f.db.Query(qb.String(), args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanFullResource)
	}
}
