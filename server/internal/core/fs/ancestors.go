package fs

import (
	"github.com/google/uuid"
)

type ResourceAncestor struct {
	ID          uuid.UUID
	ParentID    *uuid.UUID
	Name        string
	Permissions []byte
}

func (r Resource) GetAncestors() ([]ResourceAncestor, error) {
	if a, err := r.f.db.GetAncestors(r.f.ctx, r.id); err != nil {
		return nil, err
	} else {
		res := make([]ResourceAncestor, len(a))
		for i, e := range a {
			res[i] = ResourceAncestor{
				ID:          e.ID,
				ParentID:    e.Parent,
				Name:        e.Name,
				Permissions: e.Permissions,
			}
		}
		return res, nil
	}
}
