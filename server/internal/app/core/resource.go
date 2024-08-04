package core

import (
	"context"
	"errors"
	"fmt"
	"io"
	"mime"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/sirupsen/logrus"
)

const (
	PermissionReadOnly  = 1
	PermissionReadWrite = 3
	PermissionAdmin     = 127
	PermissionOwner     = 255
)

var (
	ErrInsufficientPermissions = errors.New("insufficient permissions")
	ErrResourceNotCollection   = errors.New("cannot add member to non-collection resource")
)

type ResourceInfo interface {
	ID() uuid.UUID
	Name() string
	Size() int64
	Permission() int
	ModTime() time.Time
	IsDir() bool
	ETag() string
	ContentType() string
}

type Resource interface {
	ResourceInfo
	OpenRead(start, length int64) (io.ReadCloser, error)
	OpenWrite(ctx context.Context) (io.WriteCloser, error)
	ReadDir(ctx context.Context) ([]Resource, error)
	CreateMemberResource(ctx context.Context, id uuid.UUID, name string, dir bool) (Resource, error)
	DeleteRecursive(ctx context.Context, hardDelete bool) error
}

type resource struct {
	db         *db.DbHandler
	storage    Storage
	id         uuid.UUID
	parentID   *uuid.UUID
	name       string
	size       int64
	userID     int32
	permission int
	collection bool
	modTime    time.Time
	etag       string
}

func (r resource) ID() uuid.UUID { return r.id }

func (r resource) Permission() int { return r.permission }

func (r resource) ParentID() *uuid.UUID { return r.parentID }

func (r resource) Name() string { return r.name }

func (r resource) Size() int64 { return r.size }

func (r resource) ModTime() time.Time { return r.modTime }

func (r resource) IsDir() bool { return r.collection }

func (r resource) ETag() string {
	if r.etag != "" {
		return r.etag
	}
	// The Apache http 2.4 web server by default concatenates the
	// modification time and size of a file.
	return fmt.Sprintf(`"%x%x"`, r.modTime.UnixMilli(), r.size)
}

func (r resource) ContentType() string {
	mimeType := mime.TypeByExtension(filepath.Ext(r.name))
	if mimeType != "" {
		return mimeType
	}
	return "application/octet-stream"
}

func (r resource) OpenRead(start, length int64) (io.ReadCloser, error) {
	if r.permission < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	return r.storage.OpenRead(r.id, start, length)
}

func (r resource) OpenWrite(ctx context.Context) (io.WriteCloser, error) {
	if r.permission < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	return r.storage.OpenWrite(r.id, func(len int, etag string) error {
		return r.db.Queries().UpdateResourceContents(ctx, sql.UpdateResourceContentsParams{
			ID:   r.id,
			Size: pgtype.Int4{Int32: int32(len), Valid: true},
			Etag: pgtype.Text{String: etag, Valid: true},
		})
	})
}

func (r resource) ReadDir(ctx context.Context) ([]Resource, error) {
	if r.permission < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	children, err := r.db.Queries().ReadDir(ctx, sql.ReadDirParams{ID: r.id, UserID: r.userID, IncludeRoot: false, Recursive: false})
	if err != nil {
		return nil, err
	}

	result := make([]Resource, len(children))
	for i, c := range children {
		permission := r.Permission()
		if c.Permission.Valid && int(c.Permission.Int32) > permission {
			permission = int(c.Permission.Int32)

		}
		result[i] = resource{
			db:         r.db,
			storage:    r.storage,
			id:         c.ID,
			userID:     r.userID,
			permission: permission,
			parentID:   &r.id,
			name:       c.Name,
			size:       int64(c.Size.Int32),
			modTime:    c.Modified.Time,
			collection: c.Dir,
			etag:       c.Etag.String,
		}
	}
	return result, nil
}

func (r resource) CreateMemberResource(ctx context.Context, id uuid.UUID, name string, dir bool) (Resource, error) {
	if r.permission < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	if !r.collection {
		return resource{}, ErrResourceNotCollection
	}
	var result sql.Resource
	err := r.db.RunInTx(ctx, func(q *sql.Queries) error {
		var err error
		if result, err = q.CreateResource(ctx, sql.CreateResourceParams{ID: id, Parent: &r.id, Name: name, Dir: dir}); err != nil {
			return err
		}
		return q.UpdateResourceModified(ctx, r.id)
	})
	if err != nil {
		return nil, err
	}
	return resource{
		db:         r.db,
		storage:    r.storage,
		id:         id,
		parentID:   &r.id,
		userID:     r.userID,
		permission: r.permission,
		name:       result.Name,
		size:       0,
		modTime:    result.Modified.Time,
		collection: dir,
		etag:       "",
	}, nil
}

func (r resource) DeleteRecursive(ctx context.Context, hardDelete bool) error {
	if r.permission < PermissionReadWrite {
		return ErrInsufficientPermissions
	}
	// TODO: versioning
	return r.db.RunInTx(ctx, func(q *sql.Queries) error {
		if hardDelete {
			deleted, err := q.HardDeleteRecursive(ctx, r.id)
			if err != nil {
				return err
			}
			errors := r.storage.Delete(deleted)
			for err := range errors {
				logrus.Warn(err)
			}
		} else {
			if err := q.DeleteRecursive(ctx, r.id); err != nil {
				return err
			}
		}

		if r.parentID != nil {
			return q.UpdateResourceModified(ctx, *r.parentID)
		}
		return nil
	})
}
