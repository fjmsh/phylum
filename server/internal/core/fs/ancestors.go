package fs

import (
	"strings"

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

func (r Resource) GetPath() (string, error) {
	if a, err := r.f.db.GetAncestors(r.f.ctx, r.id); err != nil {
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
