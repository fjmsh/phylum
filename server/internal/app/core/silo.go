package core

import (
	"context"
	"io"
	"io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/sirupsen/logrus"
)

type Silo interface {
	ID() uuid.UUID
	Name() string
	Owner() string
	StorageName() string
	OpenRead(ctx context.Context, id uuid.UUID, start, length int64) (io.ReadCloser, error)
	OpenWrite(ctx context.Context, id uuid.UUID) (io.WriteCloser, error)
	ReadDir(ctx context.Context, id uuid.UUID, includeRoot bool, recursive bool) ([]FileInfo, error)
	DeleteRecursive(ctx context.Context, id uuid.UUID, hardDelete bool) error
	ResourceByPath(ctx context.Context, path string) (File, error)
	Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error
	CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error
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

func (s *silo) OpenRead(ctx context.Context, id uuid.UUID, start, length int64) (io.ReadCloser, error) {
	return s.storage.OpenRead(id, start, length)
}

func (s *silo) OpenWrite(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return s.storage.OpenWrite(id, func(len int, etag string) error {
		return s.db.Queries().UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
			ID:   id,
			Size: pgtype.Int4{Int32: int32(len), Valid: true},
			Etag: pgtype.Text{String: etag, Valid: true},
		})
	})
}

func (s *silo) ReadDir(ctx context.Context, id uuid.UUID, includeRoot bool, recursive bool) ([]FileInfo, error) {
	children, err := s.db.Queries().ReadDir(ctx, sql.ReadDirParams{ID: id, IncludeRoot: includeRoot, Recursive: recursive})
	if err != nil {
		return nil, err
	}

	result := make([]FileInfo, len(children))
	for i, c := range children {
		result[i] = fileInfo{
			name:       c.Name,
			size:       int64(c.Size.Int32),
			modTime:    c.Modified.Time,
			collection: c.Dir,
			id:         c.ID,
			etag:       c.Etag.String,
		}
	}
	return result, nil
}

func (s *silo) DeleteRecursive(ctx context.Context, id uuid.UUID, hardDelete bool) error {
	// TODO: versioning
	return s.db.RunInTx(ctx, func(q *sql.Queries) error {
		p, err := q.ResourceById(ctx, id)
		if err != nil {
			return err
		}

		if hardDelete {
			deleted, err := q.HardDeleteRecursive(ctx, id)
			if err != nil {
				return err
			}
			errors := s.storage.Delete(deleted)
			for err := range errors {
				logrus.Warn(err)
			}
		} else {
			if err = q.DeleteRecursive(ctx, id); err != nil {
				return err
			}
		}

		if p.Parent != nil {
			return q.UpdateResourceModified(ctx, *p.Parent)
		}
		return nil
	})
}

func (s *silo) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return s.db.RunInTx(ctx, func(q *sql.Queries) error {
		if err := q.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			return err
		}
		return q.UpdateResourceModified(ctx, parent)
	})
}

func (s *silo) Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error {
	return s.db.Queries().Rename(ctx, sql.RenameParams{ID: id, Parent: parent, Name: name})
}

func (s *silo) ResourceByPath(ctx context.Context, path string) (File, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := s.db.Queries().ResourceByPath(ctx, sql.ResourceByPathParams{Root: s.root, Search: segments})
	if err != nil {
		return nil, fs.ErrNotExist
	}

	//TODO: Permissions checks

	return file{
		fileInfo: fileInfo{
			id:         res.ID,
			name:       res.Name,
			size:       int64(res.Size.Int32),
			collection: res.Dir,
			modTime:    res.Modified.Time,
			etag:       res.Etag.String,
		},
		silo: s,
	}, nil
}
