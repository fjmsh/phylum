package phylumfs

import (
	"context"
	"encoding/base64"
	"fmt"
	"hash"
	"io"
	"io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/sirupsen/logrus"
)

type PhylumFs struct {
	queries sql.Queries
	cs      ContentStore
}

func New(conn *pgx.Conn) PhylumFs {
	queries := *sql.New(conn)
	cs, err := NewLocalContentStore("srv")
	if err != nil {
		panic(err)
	}
	return PhylumFs{queries: queries, cs: cs}
}

func (p PhylumFs) Mkroot(ctx context.Context, id uuid.UUID, name string) error {
	if _, err := p.queries.FindRoot(ctx, name); err == nil {
		return fmt.Errorf("root directory already exists: %s", name)
	} else {
		return p.queries.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: nil, Name: name, Dir: true})
	}
}

func (p PhylumFs) Rmroot(ctx context.Context, name string) error {
	if root, err := p.queries.FindRoot(ctx, name); err == nil {
		return p.DeleteRecursive(ctx, root.ID)
	} else {
		return fmt.Errorf("root directory does not exist: %s", name)
	}
}

func (p PhylumFs) Open(id uuid.UUID) (io.ReadCloser, error) {
	return p.cs.Open(id)
}

func (p PhylumFs) ReadDir(ctx context.Context, id uuid.UUID, recursive bool) ([]sql.ReadDirRow, error) {
	return p.queries.ReadDir(ctx, sql.ReadDirParams{ID: id, Recursive: recursive})
}

func (p PhylumFs) DeleteRecursive(ctx context.Context, id uuid.UUID) error {
	_, err := p.queries.DeleteRecursive(ctx, id)
	// TODO: Delete Contents
	return err
}

func (p PhylumFs) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return p.queries.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir})
}

func (p PhylumFs) UpdateContents(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return p.cs.Create(id, func(h hash.Hash, len int, err error) {
		if err == nil {
			etag := base64.StdEncoding.EncodeToString(h.Sum(nil))
			err = p.queries.UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
				ID:   id,
				Size: pgtype.Int4{Int32: int32(len), Valid: true},
				Etag: pgtype.Text{String: string(etag), Valid: true},
			})
		}
		if err != nil {
			logrus.Warn(fmt.Sprintf("Unable to update contents: %s", err))
			p.cs.Delete(id)
		}
	})
}

func (p PhylumFs) ResourceByPath(ctx context.Context, path string) (*sql.ResourceByPathRow, error) {
	segments := strings.Split(strings.TrimRight(path, "/"), "/")
	if len(segments) == 0 {
		return nil, fs.ErrInvalid
	}

	root, err := p.queries.FindRoot(ctx, segments[0])
	if err != nil {
		return nil, fs.ErrNotExist
	}

	res, err := p.queries.ResourceByPath(ctx, sql.ResourceByPathParams{Search: segments, Root: root.ID})
	if err != nil {
		return nil, fs.ErrNotExist
	}

	//TODO: Permissions checks

	return &res, nil
}
