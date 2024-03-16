package library

import (
	"context"
	"io"
	"io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
)

type Library struct {
	db   *sql.DbHandler
	root uuid.UUID
	cs   storage.Storage
}

func (l Library) OpenRead(ctx context.Context, id uuid.UUID, start, length int64) (io.ReadCloser, error) {
	return l.cs.OpenRead(id, start, length)
}

func (l Library) OpenWrite(ctx context.Context, id uuid.UUID) (io.WriteCloser, error) {
	return l.cs.OpenWrite(id, func(len int, etag string) error {
		return l.db.Queries().UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
			ID:   id,
			Size: pgtype.Int4{Int32: int32(len), Valid: true},
			Etag: pgtype.Text{String: etag, Valid: true},
		})
	})
}

func (l Library) ReadDir(ctx context.Context, id uuid.UUID, includeRoot bool, recursive bool) ([]sql.ReadDirRow, error) {
	return l.db.Queries().ReadDir(ctx, sql.ReadDirParams{ID: id, IncludeRoot: includeRoot, Recursive: recursive})
}

func (l Library) DeleteRecursive(ctx context.Context, id uuid.UUID, hardDelete bool) error {
	return l.db.RunInTx(ctx, func(q *sql.Queries) error {
		p, err := q.ResourceById(ctx, id)
		if err != nil {
			return err
		}

		query := q.DeleteRecursive
		if hardDelete {
			query = q.HardDeleteRecursive
		}
		deleted, err := query(ctx, id)
		if err == nil && hardDelete {
			for _, res := range deleted {
				if !res.Dir {
					l.cs.Delete(res.ID)
				}
			}
		}

		if p.Parent != nil {
			return q.UpdateResourceModified(ctx, *p.Parent)
		}
		return nil
	})

}

func (l Library) CreateResource(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string, dir bool) error {
	return l.db.RunInTx(ctx, func(q *sql.Queries) error {
		if err := q.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			return err
		}
		return q.UpdateResourceModified(ctx, parent)
	})
}

func (l Library) Move(ctx context.Context, id uuid.UUID, parent uuid.UUID, name string) error {
	return l.db.Queries().Rename(ctx, sql.RenameParams{ID: id, Parent: parent, Name: name})
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
