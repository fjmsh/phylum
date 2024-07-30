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
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type Silo struct {
	db      *db.DbHandler
	storage storage.Storage
	root    uuid.UUID
}

func NewSilo(db *db.DbHandler, storage storage.Storage, root uuid.UUID) *Silo {
	return &Silo{
		db:      db,
		storage: storage,
		root:    root,
	}
}

func (s *Silo) OpenRead(ctx context.Context, id uuid.UUID, start, length int64) (io.ReadCloser, error) {
	return s.storage.OpenRead(id, start, length)
}

func (s *Silo) OpenWrite(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return s.storage.OpenWrite(id, func(len int, etag string) error {
		return s.db.Queries().UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
			ID:   id,
			Size: pgtype.Int4{Int32: int32(len), Valid: true},
			Etag: pgtype.Text{String: etag, Valid: true},
		})
	})
}

func (s *Silo) ReadDir(ctx context.Context, id uuid.UUID, includeRoot bool, recursive bool) ([]FileInfo, error) {
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

func (s *Silo) DeleteRecursive(ctx context.Context, id uuid.UUID, hardDelete bool) error {
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

func (s *Silo) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return s.db.RunInTx(ctx, func(q *sql.Queries) error {
		if err := q.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			return err
		}
		return q.UpdateResourceModified(ctx, parent)
	})
}

func (s *Silo) Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error {
	return s.db.Queries().Rename(ctx, sql.RenameParams{ID: id, Parent: parent, Name: name})
}

func (s *Silo) ResourceByPath(ctx context.Context, path string) (File, error) {
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
