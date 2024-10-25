package public

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type filesystem struct {
	ctx    context.Context
	db     *db.DbHandler
	cs     storage.Storage
	rootID uuid.UUID
}

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	r, err := f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: f.rootID, Path: path})
	if err == pgx.ErrNoRows || !r.Found {
		err = fs.ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}

	return Resource{
		f:             f,
		id:            r.ID,
		name:          r.Name,
		dir:           r.Dir,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		contentSize:   r.ContentSize,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
	}, nil
}
