package publink

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type filesystem struct {
	ctx  context.Context
	db   *db.DbHandler
	cs   storage.Storage
	root uuid.UUID
}

func (f filesystem) resourceByPath(path string) (Resource, error) {
	r, err := f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: f.root, Path: path})
	if err == pgx.ErrNoRows || !r.Found {
		err = ErrNotFound
	}
	if err != nil {
		return Resource{}, err
	}

	return Resource{
		f:             f,
		id:            r.ID,
		name:          r.Name,
		dir:           r.Dir,
		path:          r.Path,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		contentSize:   r.ContentSize,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
	}, nil
}
