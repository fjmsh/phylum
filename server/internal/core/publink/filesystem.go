package publink

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type filesystem struct {
	ctx  context.Context
	db   *db.DbHandler
	cs   storage.Storage
	root uuid.UUID
}

func (f filesystem) resourceByPath(search string) (Resource, error) {
	e, err := f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Path: search, Root: &f.root})
	if len(e) == 0 {
		err = ErrNotFound
	}
	if err != nil {
		return Resource{}, err
	}
	var b strings.Builder
	found := false
	for i := len(e) - 1; i >= 0; i-- {
		if e[i].ID == f.root {
			found = true
		}
		if i != len(e)-i {
			b.WriteByte('/')
			b.WriteString(e[i].Name)
		}
	}
	if !found {
		return Resource{}, ErrNotFound
	}
	path := b.String()
	if b.Len() == 0 {
		path = "/"
	}

	r := e[0]
	return Resource{
		f:             f,
		id:            r.ID,
		name:          r.Name,
		dir:           r.Dir,
		path:          path,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		contentSize:   r.ContentSize,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
	}, nil
}
