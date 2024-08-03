package core

import (
	"context"
	"io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/sql"
)

type Silo interface {
	ID() uuid.UUID
	Name() string
	Owner() string
	StorageName() string
	ResourceByPath(ctx context.Context, path, username string) (Resource, error)
	Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error
}

type silo struct {
	db      *db.DbHandler
	name    string
	owner   string
	root    uuid.UUID
	storage Storage
}

func NewSilo(db *db.DbHandler, name, owner string, root uuid.UUID, storage Storage) Silo {
	return &silo{
		db:      db,
		name:    name,
		owner:   owner,
		root:    root,
		storage: storage,
	}
}

func (s *silo) ID() uuid.UUID {
	return s.root
}

func (s *silo) Name() string {
	return s.name
}

func (s *silo) Owner() string {
	return s.owner
}

func (s *silo) StorageName() string {
	return s.storage.Name()
}

func (s *silo) Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error {
	return s.db.Queries().Rename(ctx, sql.RenameParams{ID: id, Parent: parent, Name: name})
}

func (s *silo) ResourceByPath(ctx context.Context, path, username string) (Resource, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := s.db.Queries().ResourceByPath(ctx, sql.ResourceByPathParams{Root: s.root, Search: segments, Username: username})
	if err != nil {
		return nil, fs.ErrNotExist
	}

	if !res.Permission.Valid || res.Permission.Int32 == 0 {
		return nil, ErrInsufficientPermissions
	}

	return resource{
		db:         s.db,
		storage:    s.storage,
		id:         res.ID,
		username:   username,
		permission: int(res.Permission.Int32),
		parentID:   res.Parent,
		name:       res.Name,
		size:       int64(res.Size.Int32),
		collection: res.Dir,
		modTime:    res.Modified.Time,
		etag:       res.Etag.String,
	}, nil
}
