package core

import (
	"context"
	"io"
	"io/fs"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type FileSystem interface {
	OpenWithRoot(Resource) FileSystem
	ResourceByPath(path string) (Resource, error)
	ResourceByID(id uuid.UUID) (Resource, error)
	OpenRead(r Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(r Resource) (io.WriteCloser, error)
	ReadDir(r Resource) ([]Resource, error)
	CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error)
	DeleteRecursive(r Resource, hardDelete bool) error
	UpdateName(r Resource, name string) error
	UpdateParent(r Resource, parent uuid.UUID) error
	UpdatePermissions(r Resource, userID int32, permission int32) error
	UpdateOwner(r Resource, userID int32) error
}

var rootUUID = uuid.UUID{}

type filesystem struct {
	db   *db.DbHandler
	ctx  context.Context
	cs   storage.Storage
	root Resource
	user int32
}

func OpenFileSystem(db *db.DbHandler, ctx context.Context, cs storage.Storage, root Resource, user int32) (FileSystem, error) {
	if root == nil {
		if res, err := db.Queries().RootResource(ctx, user); err == nil {
			root = resource{
				id:         rootUUID,
				owner:      res.Owner,
				permission: res.Permission,
				parentID:   rootUUID,
				name:       res.Name,
				size:       0,
				collection: true,
				modTime:    res.Modified.Time,
				delTime:    nil,
				etag:       "",
			}
		} else {
			return nil, err
		}
	}
	return filesystem{
		db:   db,
		ctx:  ctx,
		cs:   cs,
		root: root,
		user: user,
	}, nil
}

func (f filesystem) OpenWithRoot(root Resource) FileSystem {
	return filesystem{
		db:   f.db,
		ctx:  f.ctx,
		cs:   f.cs,
		root: root,
		user: f.user,
	}
}

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := f.db.Queries().ResourceByPath(f.ctx, sql.ResourceByPathParams{Root: f.root.ID(), Permission: f.root.Permission(), Search: segments, UserID: f.user})
	if err == pgx.ErrNoRows || res.Permission == 0 {
		err = fs.ErrNotExist
	}
	if err != nil {
		return nil, err
	}

	return resource{
		id:         res.ID,
		owner:      res.Owner,
		permission: res.Permission,
		parentID:   res.Parent,
		name:       res.Name,
		size:       res.Size.Int64,
		collection: res.Dir,
		modTime:    res.Modified.Time,
		delTime:    nil,
		etag:       res.Etag.String,
	}, nil
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	res, err := f.db.Queries().ResourceByID(f.ctx, sql.ResourceByIDParams{Root: f.root.ID(), Permission: f.root.Permission(), ResourceID: id, UserID: f.user})
	// TODO: check found
	if err == pgx.ErrNoRows || !res.Found || res.Permission == 0 {
		err = fs.ErrNotExist
	}
	if err != nil {
		return nil, err
	}

	var delTime *time.Time
	if res.Deleted.Valid {
		delTime = &res.Deleted.Time
	}
	return resource{
		id:         res.ID,
		owner:      res.Owner,
		permission: res.Permission,
		parentID:   res.Parent,
		name:       res.Name,
		size:       res.Size.Int64,
		collection: res.Dir,
		modTime:    res.Modified.Time,
		delTime:    delTime,
		etag:       res.Etag.String,
	}, nil
}
func (f filesystem) OpenRead(r Resource, start, length int64) (io.ReadCloser, error) {
	if r.Permission() < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenRead(r.ID(), start, length)
}

func (f filesystem) OpenWrite(r Resource) (io.WriteCloser, error) {
	if r.Permission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenWrite(r.ID(), func(len int, etag string) error {
		return f.db.Queries().UpdateResourceContents(f.ctx, sql.UpdateResourceContentsParams{
			ID:   r.ID(),
			Size: pgtype.Int8{Int64: int64(len), Valid: true},
			Etag: pgtype.Text{String: etag, Valid: true},
		})
	})
}

func (f filesystem) ReadDir(r Resource) ([]Resource, error) {
	if r.Permission() < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	children, err := f.db.Queries().ReadDir(f.ctx, sql.ReadDirParams{
		ID:          r.ID(),
		Permission:  r.Permission(),
		UserID:      f.user,
		IncludeRoot: false,
		Recursive:   false,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Resource, len(children))
	for i, c := range children {
		result[i] = resource{
			id:         c.ID,
			owner:      c.Owner,
			permission: c.Permission,
			parentID:   r.ParentID(),
			name:       c.Name,
			size:       c.Size.Int64,
			modTime:    c.Modified.Time,
			delTime:    nil,
			collection: c.Dir,
			etag:       c.Etag.String,
		}
	}
	return result, nil
}

func (f filesystem) CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error) {
	if !r.IsDir() {
		return nil, ErrResourceNotCollection
	}
	if r.Permission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	var result sql.Resource
	err := f.db.RunInTx(f.ctx, func(q *sql.Queries) error {
		var err error
		if result, err = q.CreateResource(f.ctx, sql.CreateResourceParams{ID: id, Owner: f.user, Parent: r.ID(), Name: name, Dir: dir}); err != nil {
			return err
		}
		return q.UpdateResourceModified(f.ctx, r.ID())
	})
	if err != nil {
		return nil, err
	}
	return resource{
		id:         id,
		owner:      r.Owner(),
		parentID:   r.ID(),
		permission: r.Permission(),
		name:       result.Name,
		size:       0,
		modTime:    result.Modified.Time,
		delTime:    nil,
		collection: dir,
		etag:       "",
	}, nil
}

func (f filesystem) DeleteRecursive(r Resource, hardDelete bool) error {
	if r.Permission() < PermissionReadWrite {
		return ErrInsufficientPermissions
	}
	// TODO: versioning
	return f.db.RunInTx(f.ctx, func(q *sql.Queries) error {
		if hardDelete {
			deleted, err := q.HardDeleteRecursive(f.ctx, r.ID())
			if err != nil {
				return err
			}
			errors := f.cs.Delete(deleted)
			for err := range errors {
				logrus.Warn(err)
			}
		} else {
			if err := q.DeleteRecursive(f.ctx, r.ID()); err != nil {
				return err
			}
		}

		emptyUUID := uuid.UUID{}
		if r.ParentID() != emptyUUID {
			return q.UpdateResourceModified(f.ctx, r.ParentID())
		}
		return nil
	})
}

func (f filesystem) UpdateName(r Resource, name string) error {
	return f.db.Queries().UpdateResourceName(f.ctx, sql.UpdateResourceNameParams{ID: r.ID(), Name: name})
}

func (f filesystem) UpdateParent(r Resource, parent uuid.UUID) error {
	emptyUUID := uuid.UUID{}
	if r.ParentID() == emptyUUID {
		return ErrCannotReparentRootResource
	}
	return f.db.Queries().UpdateResourceParent(f.ctx, sql.UpdateResourceParentParams{ID: r.ID(), Parent: parent})
}

func (f filesystem) UpdatePermissions(r Resource, userID int32, permission int32) error {
	if r.Permission() < PermissionAdmin {
		return ErrInsufficientPermissions
	}
	if permission > PermissionAdmin {
		return ErrCannotGrantOwnerPermission
	}

	return f.db.Queries().UpdatePermissionsForResource(f.ctx, sql.UpdatePermissionsForResourceParams{
		ResourceID: r.ID(),
		UserID:     userID,
		Permission: permission,
	})
}

func (f filesystem) UpdateOwner(r Resource, userID int32) error {
	if r.Owner() != f.user {
		return ErrInsufficientPermissions
	}

	return f.db.Queries().UpdateResourceOwner(f.ctx, sql.UpdateResourceOwnerParams{
		ID:    r.ID(),
		Owner: userID,
	})
}
