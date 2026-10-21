package core

import (
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/jackc/pgx/v5"
)

func (f *FileSystem) Search(query string, includeDeleted bool) ([]Resource, error) {
	qb := strings.Builder{}
	qb.WriteString(fullResourceQuery)
	qb.WriteString("WHERE f_prepare_search(r.name) %> @query::TEXT")
	if !includeDeleted {
		qb.WriteString("\nAND r.deleted IS NULL")
	}
	if f.userFilesPrivilege&ResourcePermissionRead != ResourcePermissionRead {
		qb.WriteString("\nAND r.permissions[@user_id::INT]::INTEGER <> 0")
	}
	qb.WriteString("\nORDER BY word_similarity(f_prepare_search(r.name), @query::TEXT) DESC")

	args := pgx.NamedArgs{
		"query":                strings.ToLower(query),
		"user_files_privilege": f.userFilesPrivilege,
		"user_id":              f.userID,
	}

	if rows, err := f.db.Query(qb.String(), args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanFullResource)
	}
}

func (f *FileSystem) SearchWithRoot(root Resource, query string, includeDeleted bool) ([]Resource, error) {
	n, qq := selectResourceTree(root.id, includeDeleted)
	var r exp.AliasedExpression
	q, r := selectResources(qq, n)
	q = q.Where(goqu.L("f_prepare_search(?) %> ?::TEXT", r.Col("name"), query)).
		Order(goqu.L("word_similarity(f_prepare_search(?), ?::TEXT)", r.Col("name"), query).Desc())

	query, args, _ := q.ToSQL()
	if rows, err := f.db.Query(query, args...); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanResourceWithoutParent)
	}
}
