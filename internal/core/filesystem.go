package core

import (
	"context"
	"io"
	"io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type FileSystem struct {
	db             *sql.DbHandler
	storageManager *storage.Manager
}

func OpenFileSystem(db *sql.DbHandler, storageManager *storage.Manager) (*FileSystem, error) {
	fs := &FileSystem{db: db, storageManager: storageManager}
	if root, err := db.Queries().ResourceById(context.Background(), uuid.UUID{}); err != nil {
		logrus.Info("Root directory not found. Creating")
		if err := db.Queries().CreateResource(context.Background(), sql.CreateResourceParams{ID: uuid.UUID{}, Name: "root", Dir: true}); err != nil {
			logrus.Fatal("Unable to create root directory: " + err.Error())
		}
	} else if !root.Dir {
		logrus.Fatal("Root is not a directory?!")
	}
	return fs, nil
}

func (f *FileSystem) OpenRead(ctx context.Context, id uuid.UUID, start, length int64) (io.ReadCloser, error) {
	return f.storageManager.OpenRead(ctx, id, start, length)
}

func (f *FileSystem) OpenWrite(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return f.storageManager.OpenWrite(id, func(len int, etag string) error {
		return f.db.Queries().UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
			ID:   id,
			Size: pgtype.Int4{Int32: int32(len), Valid: true},
			Etag: pgtype.Text{String: etag, Valid: true},
		})
	})
}

func (f *FileSystem) ReadDir(ctx context.Context, id uuid.UUID, includeRoot bool, recursive bool) ([]FileInfo, error) {
	children, err := f.db.Queries().ReadDir(ctx, sql.ReadDirParams{ID: id, IncludeRoot: includeRoot, Recursive: recursive})
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

func (f *FileSystem) DeleteRecursive(ctx context.Context, id uuid.UUID) error {
	// TODO: versioning
	hardDelete := false

	return f.db.RunInTx(ctx, func(q *sql.Queries) error {
		p, err := q.ResourceById(ctx, id)
		if err != nil {
			return err
		}

		if hardDelete {
			deleted, err := q.HardDeleteRecursive(ctx, id)
			if err != nil {
				return err
			}
			errors := f.storageManager.Delete(deleted)
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

func (f *FileSystem) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return f.db.RunInTx(ctx, func(q *sql.Queries) error {
		if err := q.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			return err
		}
		return q.UpdateResourceModified(ctx, parent)
	})
}

func (f *FileSystem) Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error {
	return f.db.Queries().Rename(ctx, sql.RenameParams{ID: id, Parent: parent, Name: name})
}

func (f *FileSystem) ResourceByPath(ctx context.Context, path string) (File, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := f.db.Queries().ResourceByPath(ctx, segments)
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
		fs: f,
	}, nil
}
