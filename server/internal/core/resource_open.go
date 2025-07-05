package core

import (
	"fmt"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f *FileSystem) ReadDir(r Resource, recursive bool) ([]Resource, error) {
	return f.ReadDirExtended(r, recursive, false, false)
}

func (f *FileSystem) ReadDirExtended(r Resource, recursive, includeDeleted, orderByDepth bool) ([]Resource, error) {
	if !r.Dir() {
		return nil, ErrResourceNotCollection
	}

	var q *goqu.SelectDataset
	if !recursive {
		_, q = selectDirectChildren(r.id, r.deleted, includeDeleted)
	} else {
		n, qq := selectResourceTree(r.id, includeDeleted)
		id := r.id
		var r exp.AliasedExpression
		q, r = selectResources(qq, n)
		q = q.Where(r.Col("id").Neq(id))
		if orderByDepth {
			q = q.Order(n.Col("depth").Asc())
		}
	}

	query, args, _ := q.ToSQL()
	if rows, err := f.db.Query(query, args...); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanResourceWithoutParent)
	}
}

func (f *FileSystem) Walk(r Resource, depth int, fn func(Resource, string) error) error {
	if !r.dir {
		return fn(r, r.name)
	}

	pathMap := make(map[uuid.UUID]string)
	pathMap[r.id] = ""
	err := fn(r, "/")
	if err != nil {
		return err
	}
	if depth <= 0 {
		return nil
	}

	children, err := f.ReadDirExtended(r, depth > 1, false, true)
	if err != nil {
		return err
	}

	for _, c := range children {
		path := pathMap[c.parentID.Bytes] + "/" + c.name
		fmt.Println(c.name, path)
		if err := fn(c, path); err != nil {
			return err
		}
		if c.dir {
			pathMap[c.id] = path
		}
	}
	return nil
}
