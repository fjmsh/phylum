package vfs

import (
	"context"
	"encoding/base64"
	"hash"
	"io"
	iofs "io/fs"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type Vfs struct {
	queries sql.Queries
	root    uuid.UUID
	cs      storage.Storage
}

func (fs Vfs) Open(id uuid.UUID, flag int) (io.ReadWriteCloser, error) {
	return fs.cs.Open(id, flag, nil)
}

func (fs Vfs) ReadDir(ctx context.Context, id uuid.UUID, includeRoot bool, recursive bool) ([]sql.ReadDirRow, error) {
	return fs.queries.ReadDir(ctx, sql.ReadDirParams{ID: id, IncludeRoot: includeRoot, Recursive: recursive})
}

func (fs Vfs) DeleteRecursive(ctx context.Context, id uuid.UUID, hardDelete bool) error {
	query := fs.queries.DeleteRecursive
	if hardDelete {
		query = fs.queries.HardDeleteRecursive
	}
	deleted, err := query(ctx, id)
	if err == nil && hardDelete {
		for _, res := range deleted {
			if !res.Dir {
				fs.cs.Delete(res.ID)
			}
		}
	}
	return err
}

func (fs Vfs) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return fs.queries.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir})
}

func (fs Vfs) Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error {
	return fs.queries.Rename(ctx, sql.RenameParams{ID: id, Parent: parent, Name: name})
}

func (fs Vfs) UpdateContents(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return fs.cs.Open(id, os.O_CREATE|os.O_RDWR|os.O_TRUNC, func(h hash.Hash, len int, err error) {
		if err == nil {
			etag := base64.StdEncoding.EncodeToString(h.Sum(nil))
			err = fs.queries.UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
				ID:   id,
				Size: pgtype.Int4{Int32: int32(len), Valid: true},
				Etag: pgtype.Text{String: string(etag), Valid: true},
			})
		}
		if err != nil {
			logrus.Warn("Unable to update contents: " + err.Error())
			fs.cs.Delete(id)
		}
	})
}

func (fs Vfs) ResourceByPath(ctx context.Context, path string) (sql.ResourceByPathRow, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := fs.queries.ResourceByPath(ctx, sql.ResourceByPathParams{Search: segments, Root: fs.root})
	if err != nil {
		return sql.ResourceByPathRow{}, iofs.ErrNotExist
	}

	//TODO: Permissions checks

	return res, nil
}
