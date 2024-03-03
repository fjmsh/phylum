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
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/phylumsql"
	"github.com/sirupsen/logrus"
)

type PhylumFs struct {
	q  phylumsql.Queries
	cs ContentStore
}

func New(q phylumsql.Queries) PhylumFs {
	cs, err := NewLocalContentStore("srv")
	if err != nil {
		panic(err)
	}
	return PhylumFs{q: q, cs: cs}
}

func (p PhylumFs) Mkroot(ctx context.Context, id uuid.UUID, name string) error {
	if _, err := p.q.FindRoot(ctx, name); err == nil {
		return fmt.Errorf("root directory already exists: %s", name)
	} else {
		return p.q.CreateResource(ctx, phylumsql.CreateResourceParams{ID: id, Parent: nil, Name: name, Dir: true})
	}
}

func (p PhylumFs) Rmroot(ctx context.Context, name string) error {
	if root, err := p.q.FindRoot(ctx, name); err == nil {
		return p.DeleteRecursive(ctx, root.ID)
	} else {
		return fmt.Errorf("root directory does not exist: %s", name)
	}
}

func (p PhylumFs) Open(id uuid.UUID) (io.ReadCloser, error) {
	return p.cs.Open(id)
}

func (p PhylumFs) ReadDir(ctx context.Context, id uuid.UUID, recursive bool) ([]phylumsql.ReadDirRow, error) {
	return p.q.ReadDir(ctx, phylumsql.ReadDirParams{ID: id, Recursive: recursive})
}

func (p PhylumFs) DeleteRecursive(ctx context.Context, id uuid.UUID) error {
	_, err := p.q.DeleteRecursive(ctx, id)
	// TODO: Delete Contents
	return err
}

func (p PhylumFs) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return p.q.CreateResource(ctx, phylumsql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir})
}

func (p PhylumFs) UpdateContents(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return p.cs.Create(id, func(h hash.Hash, len int, err error) {
		if err == nil {
			etag := base64.StdEncoding.EncodeToString(h.Sum(nil))
			err = p.q.UpdateResourceContents(ctx, phylumsql.UpdateResourceContentsParams{
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

func (p PhylumFs) ResourceByPath(ctx context.Context, path string) (*phylumsql.ResourceByPathRow, error) {
	segments := strings.Split(strings.TrimRight(path, "/"), "/")
	if len(segments) == 0 {
		return nil, fs.ErrInvalid
	}

	root, err := p.q.FindRoot(ctx, segments[0])
	if err != nil {
		return nil, fs.ErrNotExist
	}

	res, err := p.q.ResourceByPath(ctx, phylumsql.ResourceByPathParams{Search: segments, Root: root.ID})
	if err != nil {
		return nil, fs.ErrNotExist
	}

	//TODO: Permissions checks

	return &res, nil
}
