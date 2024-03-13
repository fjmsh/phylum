package library

import (
	"context"
	"encoding/base64"
	"hash"
	"io"
	"io/fs"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type Library struct {
	db   *sql.DbHandler
	root uuid.UUID
	cs   storage.Storage
}

func (l Library) Open(id uuid.UUID, flag int) (io.ReadWriteCloser, error) {
	return l.cs.Open(id, flag, nil)
}

func (l Library) ReadDir(ctx context.Context, id uuid.UUID, includeRoot bool, recursive bool) ([]sql.ReadDirRow, error) {
	return l.db.Queries().ReadDir(ctx, sql.ReadDirParams{ID: id, IncludeRoot: includeRoot, Recursive: recursive})
}

func (l Library) DeleteRecursive(ctx context.Context, id uuid.UUID, hardDelete bool) error {
	query := l.db.Queries().DeleteRecursive
	if hardDelete {
		query = l.db.Queries().HardDeleteRecursive
	}
	deleted, err := query(ctx, id)
	if err == nil && hardDelete {
		for _, res := range deleted {
			if !res.Dir {
				l.cs.Delete(res.ID)
			}
		}
	}
	return err
}

func (l Library) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return l.db.Queries().CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir})
}

func (l Library) Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error {
	return l.db.Queries().Rename(ctx, sql.RenameParams{ID: id, Parent: parent, Name: name})
}

func (l Library) UpdateContents(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return l.cs.Open(id, os.O_CREATE|os.O_RDWR|os.O_TRUNC, func(h hash.Hash, len int, err error) {
		if err == nil {
			etag := base64.StdEncoding.EncodeToString(h.Sum(nil))
			err = l.db.Queries().UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
				ID:   id,
				Size: pgtype.Int4{Int32: int32(len), Valid: true},
				Etag: pgtype.Text{String: string(etag), Valid: true},
			})
		}
		if err != nil {
			logrus.Warn("Unable to update contents: " + err.Error())
			l.cs.Delete(id)
		}
	})
}

func (l Library) ResourceByPath(ctx context.Context, path string) (sql.ResourceByPathRow, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := l.db.Queries().ResourceByPath(ctx, sql.ResourceByPathParams{Search: segments, Root: l.root})
	if err != nil {
		return sql.ResourceByPathRow{}, fs.ErrNotExist
	}

	//TODO: Permissions checks

	return res, nil
}
