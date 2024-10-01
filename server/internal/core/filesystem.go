package core

import (
	"context"
	"crypto/sha256"
	"errors"
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

var (
	ErrInsufficientPermissions    = errors.New("insufficient permissions")
	ErrCannotGrantOwnerPermission = errors.New("cannot grant owner permission")
	ErrResourceNotCollection      = errors.New("cannot add member to non-collection resource")
	ErrIDNotSpecified             = errors.New("resource id not specified")
	ErrNameInvalid                = errors.New("name invalid")
	ErrResourceNameConflict       = errors.New("name conflict")
	ErrResourceIDConflict         = errors.New("id conflict")
	ErrMoveTargetSubdirectory     = errors.New("move target subdirectory")
)

type FileSystem interface {
	WithDb(*db.DbHandler) FileSystem
	RunInTx(fn func(FileSystem) error) error
	RootID() uuid.UUID
	ResourceByPath(path string) (Resource, error)
	ResourceByID(id uuid.UUID) (Resource, error)
	OpenRead(r Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(r Resource) (io.WriteCloser, error)
	ReadDir(r Resource) ([]Resource, error)
	CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error)
	DeleteRecursive(r Resource, hardDelete bool) (uuid.UUIDs, error)
	Move(r Resource, name string, parent *uuid.UUID) (Resource, error)
	UpdatePermissions(r Resource, username string, permission Permission) error
}

type filesystem struct {
	db       *db.DbHandler
	ctx      context.Context
	cs       storage.Storage
	rootID   uuid.UUID
	username string
}

func OpenFileSystem(dbh *db.DbHandler, ctx context.Context, cs storage.Storage, username string, rootID uuid.UUID) FileSystem {
	return filesystem{
		db:       dbh,
		ctx:      ctx,
		cs:       cs,
		rootID:   rootID,
		username: username,
	}
}

func (f filesystem) RootID() uuid.UUID {
	return f.rootID
}

func (f filesystem) WithDb(db *db.DbHandler) FileSystem {
	return filesystem{
		db:       db,
		ctx:      f.ctx,
		cs:       f.cs,
		rootID:   f.rootID,
		username: f.username,
	}
}

func (f filesystem) RunInTx(fn func(FileSystem) error) error {
	return f.db.WithTx(f.ctx, func(db *db.DbHandler) error {
		return fn(f.WithDb(db))
	})
}

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: f.rootID, Search: segments})
	if err == pgx.ErrNoRows {
		err = fs.ErrNotExist
	}
	if err != nil {
		return nil, err
	}
	return f.ResourceByID(res.ID)
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: f.rootID, ResourceID: id, Username: f.username})
	// TODO: verify found
	if err == pgx.ErrNoRows || !res.Found || res.UserPermission == 0 {
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
		id:                   res.ID,
		userPermission:       res.UserPermission,
		parentID:             res.Parent,
		name:                 res.Name,
		size:                 res.Size.Int64,
		collection:           res.Dir,
		modTime:              res.Modified.Time,
		delTime:              delTime,
		sha256sum:            res.Sha256sum.String,
		permissions:          res.Permissions,
		inheritedPermissions: res.InheritedPermissions,
	}, nil
}
func (f filesystem) OpenRead(r Resource, start, length int64) (io.ReadCloser, error) {
	if r.UserPermission() < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenRead(r.ID(), start, length)
}

func (f filesystem) OpenWrite(r Resource) (io.WriteCloser, error) {
	if r.UserPermission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenWrite(r.ID(), sha256.New, func(len int, sum string) error {
		return f.db.UpdateResourceContents(f.ctx, db.UpdateResourceContentsParams{
			ID:        r.ID(),
			Size:      pgtype.Int8{Int64: int64(len), Valid: true},
			Sha256sum: pgtype.Text{String: sum, Valid: true},
		})
	})
}

func (f filesystem) ReadDir(r Resource) ([]Resource, error) {
	if r.UserPermission() < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	if !r.IsDir() {
		return nil, ErrResourceNotCollection
	}
	children, err := f.db.ReadDir(f.ctx, db.ReadDirParams{
		ID:          r.ID(),
		IncludeRoot: false,
		Recursive:   false,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Resource, len(children))
	for i, c := range children {
		result[i] = resource{
			id:             c.ID,
			parentID:       c.Parent,
			name:           c.Name,
			size:           c.Size.Int64,
			modTime:        c.Modified.Time,
			delTime:        nil,
			collection:     c.Dir,
			sha256sum:      c.Sha256sum.String,
			userPermission: 0, // Not part of the query since it is never needed
			permissions:    c.Permissions,
		}
	}
	return result, nil
}

func (f filesystem) CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error) {
	if !r.IsDir() {
		return nil, ErrResourceNotCollection
	}
	if r.UserPermission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	if id == uuid.Nil {
		return nil, ErrIDNotSpecified
	}
	if name == "" || checkNameInvalid(name) {
		return nil, ErrNameInvalid
	}
	var result db.Resource
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		parent := r.ID()
		if result, err = d.CreateResource(f.ctx, db.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			if strings.Contains(err.Error(), "resources_pkey") {
				return ErrResourceIDConflict
			}
			return err
		}
		return d.UpdateResourceModified(f.ctx, r.ID())
	})
	if err != nil {
		return nil, err
	}
	return resource{
		id:             id,
		parentID:       result.Parent,
		userPermission: r.UserPermission(),
		name:           result.Name,
		size:           0,
		modTime:        result.Modified.Time,
		delTime:        nil,
		collection:     dir,
		sha256sum:      "",
		permissions:    result.Permissions,
	}, nil
}

func (f filesystem) DeleteRecursive(r Resource, hardDelete bool) (uuid.UUIDs, error) {
	if r.UserPermission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	// TODO: versioning
	var ids uuid.UUIDs
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if hardDelete {
			ids, err = d.HardDeleteRecursive(f.ctx, r.ID())
			if err != nil {
				return err
			}
			errors := f.cs.DeleteAll(ids)
			for err := range errors {
				logrus.Warn(err)
			}
		} else {
			if ids, err = d.DeleteRecursive(f.ctx, r.ID()); err != nil {
				return err
			}
		}

		parent := r.ParentID()
		if parent != nil {
			return d.UpdateResourceModified(f.ctx, *parent)
		}
		return nil
	})

	if err != nil {
		return nil, err
	}

	return ids, nil
}

func (f filesystem) UpdateName(r Resource, name string) (Resource, error) {
	if r, err := f.db.UpdateResourceName(f.ctx, db.UpdateResourceNameParams{ID: r.ID(), Name: name}); err != nil {
		return nil, err
	} else {
		return resource{
			id:             r.ID,
			parentID:       r.Parent,
			userPermission: 0, // TODO: set correctly
			name:           r.Name,
			size:           r.Size.Int64,
			modTime:        r.Modified.Time,
			delTime:        &r.Deleted.Time,
			collection:     r.Dir,
			sha256sum:      r.Sha256sum.String,
			permissions:    r.Permissions,
		}, nil
	}
}

func (f filesystem) Move(r Resource, name string, parent *uuid.UUID) (Resource, error) {
	if r.ParentID() == nil {
		return nil, ErrInsufficientPermissions
	}
	if name == r.Name() {
		name = ""
	}
	if checkNameInvalid(name) {
		return nil, ErrNameInvalid
	}
	if parent == r.ParentID() {
		parent = nil
	}

	// Check source directory permissions
	oldParent, err := f.ResourceByID(*r.ParentID())
	if err != nil {
		return nil, err
	}
	if oldParent.UserPermission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}

	// Check target directory permissions (if applicable)
	if parent != nil {
		newParent, err := f.ResourceByID(*parent)
		if err != nil {
			return nil, err
		}
		if newParent.UserPermission() < PermissionReadWrite {
			return nil, ErrInsufficientPermissions
		}

		if res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: r.ID(), ResourceID: *parent, Username: f.username}); err != nil || res.Found {
			return nil, ErrMoveTargetSubdirectory
		}
	}
	if r, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID(), Name: name, Parent: parent}); err != nil {
		if strings.Contains(err.Error(), "unique_member_resource_name") {
			return nil, ErrResourceNameConflict
		}
		return nil, err
	} else {
		return resource{
			id:             r.ID,
			parentID:       r.Parent,
			userPermission: 0, // TODO: set correctly
			name:           r.Name,
			size:           r.Size.Int64,
			modTime:        r.Modified.Time,
			delTime:        &r.Deleted.Time,
			collection:     r.Dir,
			sha256sum:      r.Sha256sum.String,
			permissions:    r.Permissions,
		}, nil
	}
}

func (f filesystem) UpdatePermissions(r Resource, username string, permission Permission) error {
	if r.UserPermission() < PermissionReadWriteShare {
		return ErrInsufficientPermissions
	}
	if permission > PermissionReadWriteShare {
		permission = PermissionReadWriteShare
	}

	return f.db.UpdatePermissionsForResource(f.ctx, db.UpdatePermissionsForResourceParams{
		ResourceID: r.ID(),
		Username:   username,
		Permission: permission,
	})
}

func checkNameInvalid(s string) bool {
	return strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
