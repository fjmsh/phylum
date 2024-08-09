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
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type FileSystem interface {
	WithDb(*db.DbHandler) FileSystem
	Root() Resource
	ResourceByPath(path string) (Resource, error)
	ResourceByID(id uuid.UUID) (Resource, error)
	OpenRead(r Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(r Resource) (io.WriteCloser, error)
	ReadDir(r Resource) ([]Resource, error)
	CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error)
	DeleteRecursive(r Resource, hardDelete bool) error
	UpdateName(r Resource, name string) error
	UpdateParent(r Resource, parent uuid.UUID) error
	UpdatePermissions(r Resource, userID int32, permission Permission) error
}

type filesystem struct {
	db   *db.DbHandler
	ctx  context.Context
	cs   storage.Storage
	root Resource
	user int32
}

func OpenFileSystem(dbh *db.DbHandler, ctx context.Context, cs storage.Storage, user int32, rootID uuid.UUID) (FileSystem, error) {
	var root Resource
	if res, err := dbh.ResourceByID(ctx, db.ResourceByIDParams{
		ResourceID: rootID,
		UserID:     user,
	}); err != nil {
		return nil, err
	} else {
		root = resource{
			id:         res.ID,
			permission: res.Permission,
			parentID:   nil,
			name:       res.Name,
			size:       0,
			collection: true,
			modTime:    res.Modified.Time,
			delTime:    nil,
			etag:       "",
		}
	}
	return filesystem{
		db:   dbh,
		ctx:  ctx,
		cs:   cs,
		root: root,
		user: user,
	}, nil
}

func (f filesystem) Root() Resource {
	return f.root
}

func (f filesystem) WithDb(db *db.DbHandler) FileSystem {
	return filesystem{
		db:   db,
		ctx:  f.ctx,
		cs:   f.cs,
		root: f.root,
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

	res, err := f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: f.root.ID(), Permission: f.root.Permission(), Search: segments, UserID: f.user})
	// TODO: Fix su should have access to all files
	if err == pgx.ErrNoRows || res.Permission == 0 {
		err = fs.ErrNotExist
	}
	if err != nil {
		return nil, err
	}

	return resource{
		id:         res.ID,
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
	res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: f.root.ID(), ResourceID: id, UserID: f.user})
	// TODO: verify found
	// TODO: Fix su should have access to all files
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
		return f.db.UpdateResourceContents(f.ctx, db.UpdateResourceContentsParams{
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
	children, err := f.db.ReadDir(f.ctx, db.ReadDirParams{
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
	var result db.Resource
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		parent := r.ID()
		if result, err = d.CreateResource(f.ctx, db.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			return err
		}
		return d.UpdateResourceModified(f.ctx, r.ID())
	})
	if err != nil {
		return nil, err
	}
	return resource{
		id:         id,
		parentID:   result.Parent,
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
	return f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		if hardDelete {
			deleted, err := d.HardDeleteRecursive(f.ctx, r.ID())
			if err != nil {
				return err
			}
			errors := f.cs.DeleteAll(deleted)
			for err := range errors {
				logrus.Warn(err)
			}
		} else {
			if err := d.DeleteRecursive(f.ctx, r.ID()); err != nil {
				return err
			}
		}

		parent := r.ParentID()
		if parent != nil {
			return d.UpdateResourceModified(f.ctx, *parent)
		}
		return nil
	})
}

func (f filesystem) UpdateName(r Resource, name string) error {
	if r.Name() == name {
		return nil
	}
	if r.Permission() < PermissionReadWrite {
		return ErrInsufficientPermissions
	}
	return f.db.UpdateResourceName(f.ctx, db.UpdateResourceNameParams{ID: r.ID(), Name: name})
}

func (f filesystem) UpdateParent(r Resource, parent uuid.UUID) error {
	if r.ParentID() == nil {
		return ErrInsufficientPermissions
	}
	if *r.ParentID() == parent {
		return nil
	}
	oldParent, err := f.ResourceByID(*r.ParentID())
	if err != nil {
		return err
	}
	if oldParent.Permission() < PermissionReadWrite {
		return ErrInsufficientPermissions
	}
	newParent, err := f.ResourceByID(parent)
	if err != nil {
		return err
	}
	if newParent.Permission() < PermissionReadWrite {
		return ErrInsufficientPermissions
	}
	return f.db.UpdateResourceParent(f.ctx, db.UpdateResourceParentParams{ID: r.ID(), Parent: parent})
}

func (f filesystem) UpdatePermissions(r Resource, userID int32, permission Permission) error {
	if r.Permission() < PermissionReadWriteShare {
		return ErrInsufficientPermissions
	}
	if permission > PermissionReadWriteShare {
		permission = PermissionReadWriteShare
	}

	return f.db.UpdatePermissionsForResource(f.ctx, db.UpdatePermissionsForResourceParams{
		ResourceID: r.ID(),
		UserID:     userID,
		Permission: permission,
	})
}
