package phylumfs

import (
	"context"
	"encoding/base64"
	"hash"
	"io"
	iofs "io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/sirupsen/logrus"
)

type Fs interface {
	rootId() uuid.UUID
	Open(id uuid.UUID) (io.ReadCloser, error)
	ReadDir(ctx context.Context, id uuid.UUID, recursive bool) ([]sql.ReadDirRow, error)
	DeleteRecursive(ctx context.Context, id uuid.UUID) error
	CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error
	UpdateContents(ctx context.Context, id uuid.UUID) (io.WriteCloser, error)
	ResourceByPath(ctx context.Context, path string) (*sql.ResourceByPathRow, error)
}

type pgxFs struct {
	queries sql.Queries
	root    uuid.UUID
	cs      contentStore
}

func (fs pgxFs) rootId() uuid.UUID {
	return fs.root
}

func (fs pgxFs) Open(id uuid.UUID) (io.ReadCloser, error) {
	return fs.cs.Open(id)
}

func (fs pgxFs) ReadDir(ctx context.Context, id uuid.UUID, recursive bool) ([]sql.ReadDirRow, error) {
	return fs.queries.ReadDir(ctx, sql.ReadDirParams{ID: id, Recursive: recursive})
}

func (fs pgxFs) DeleteRecursive(ctx context.Context, id uuid.UUID) error {
	_, err := fs.queries.DeleteRecursive(ctx, id)
	// TODO: Delete Contents
	return err
}

func (fs pgxFs) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return fs.queries.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir})
}

func (fs pgxFs) UpdateContents(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return fs.cs.Create(id, func(h hash.Hash, len int, err error) {
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

func (fs pgxFs) ResourceByPath(ctx context.Context, path string) (*sql.ResourceByPathRow, error) {
	logrus.Trace("PhylumFs.ResourceByPath called with " + path)
	segments := strings.Split(strings.Trim(path, "/"), "/")
	if len(segments) == 0 {
		return nil, iofs.ErrInvalid
	}

	res, err := fs.queries.ResourceByPath(ctx, sql.ResourceByPathParams{Search: segments, Root: fs.root})
	if err != nil {
		return nil, iofs.ErrNotExist
	}
	logrus.Trace(res)

	//TODO: Permissions checks

	return &res, nil
}
