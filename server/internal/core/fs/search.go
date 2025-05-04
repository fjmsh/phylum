package fs

import (
	"strings"

	"github.com/jackc/pgx/v5"
)

func (f filesystem) Search(query string, includeDeleted bool) ([]Resource, error) {
	qb := strings.Builder{}
	qb.WriteString(`SELECT r.*, (SELECT jsonb_agg(l.id) FROM publinks l WHERE l.root = r.id) as links FROM resources r
WHERE f_prepare_search(name) %> @query::TEXT`)
	if !includeDeleted {
		qb.WriteString("\nAND deleted IS NULL")
	}
	if !f.fullAccess {
		qb.WriteString("\nAND permissions[@username::TEXT]::integer <> 0")
	}
	qb.WriteString("\nORDER BY word_similarity(f_prepare_search(name), @query::TEXT) DESC ")

	args := pgx.NamedArgs{
		"query":    strings.ToLower(query),
		"username": f.username,
	}

	if rows, err := f.db.Query(qb.String(), args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, f.scanLinkedResource)
	}
}
