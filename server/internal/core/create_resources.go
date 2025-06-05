package core

import (
	"github.com/google/uuid"
)

type CreateResourcesParams struct {
	ID     uuid.UUID
	Parent uuid.UUID
	Name   string
	Dir    bool
}

// iteratorForCreateResources implements pgx.CopyFromSource.
type iteratorForCreateResources struct {
	rows                 []CreateResourcesParams
	skippedFirstNextCall bool
}

func (r *iteratorForCreateResources) Next() bool {
	if len(r.rows) == 0 {
		return false
	}
	if !r.skippedFirstNextCall {
		r.skippedFirstNextCall = true
		return true
	}
	r.rows = r.rows[1:]
	return len(r.rows) > 0
}

func (r iteratorForCreateResources) Values() ([]interface{}, error) {
	return []interface{}{
		r.rows[0].ID,
		r.rows[0].Parent,
		r.rows[0].Name,
		r.rows[0].Dir,
	}, nil
}

func (r iteratorForCreateResources) Err() error {
	return nil
}

// TODO: Make not public
func (f filesystem) CreateResources(arg []CreateResourcesParams) (int64, error) {
	return f.db.CopyFrom([]string{"resources"}, []string{"id", "parent", "name", "dir"}, &iteratorForCreateResources{rows: arg})
}
