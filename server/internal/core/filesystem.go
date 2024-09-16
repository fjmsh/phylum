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
	ErrCannotReparentRootResource = errors.New("cannot reparent root resource")
	ErrCannotReparentToRoot       = errors.New("cannot reparent resource to root")
	ErrIDNotSpecified             = errors.New("resource id not specified")
	ErrNameInvalid                = errors.New("name invalid")
	ErrResourceNameConflict       = errors.New("name conflict")
	ErrResourceIDConflict         = errors.New("id conflict")
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
	UpdateName(r Resource, name string) (Resource, error)
	UpdateParent(r Resource, parent uuid.UUID) (Resource, error)
	UpdatePermissions(r Resource, userID int32, permission Permission) error
	// GetPermissionsLocal(r Resource) (map[int32]Permission, error)
	// GetPermissionsInherited(r Resource) (map[int32]Permission, error)
}

type filesystem struct {
	db     *db.DbHandler
	ctx    context.Context
	cs     storage.Storage
	rootID uuid.UUID
	user   int32
}

func OpenFileSystem(dbh *db.DbHandler, ctx context.Context, cs storage.Storage, user int32, rootID uuid.UUID) (FileSystem, error) {
	return filesystem{
		db:     dbh,
		ctx:    ctx,
		cs:     cs,
		rootID: rootID,
		user:   user,
	}, nil
}

func (f filesystem) RootID() uuid.UUID {
	return f.rootID
}

func (f filesystem) WithDb(db *db.DbHandler) FileSystem {
	return filesystem{
		db:     db,
		ctx:    f.ctx,
		cs:     f.cs,
		rootID: f.rootID,
		user:   f.user,
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
	res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: f.rootID, ResourceID: id, UserID: f.user})
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
		id:         res.ID,
		permission: res.UserPermission,
		parentID:   res.Parent,
		name:       res.Name,
		size:       res.Size.Int64,
		collection: res.Dir,
		modTime:    res.Modified.Time,
		delTime:    delTime,
		sha256sum:  res.Sha256sum.String,
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
	return f.cs.OpenWrite(r.ID(), sha256.New, func(len int, sum string) error {
		return f.db.UpdateResourceContents(f.ctx, db.UpdateResourceContentsParams{
			ID:        r.ID(),
			Size:      pgtype.Int8{Int64: int64(len), Valid: true},
			Sha256sum: pgtype.Text{String: sum, Valid: true},
		})
	})
}

func (f filesystem) ReadDir(r Resource) ([]Resource, error) {
	if r.Permission() < PermissionReadOnly {
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
			id:         c.ID,
			permission: 0, // not needed
			parentID:   c.Parent,
			name:       c.Name,
			size:       c.Size.Int64,
			modTime:    c.Modified.Time,
			delTime:    nil,
			collection: c.Dir,
			sha256sum:  c.Sha256sum.String,
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
	if id == uuid.Nil {
		return nil, ErrIDNotSpecified
	}
	if name == "" {
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
		id:         id,
		parentID:   result.Parent,
		permission: r.Permission(),
		name:       result.Name,
		size:       0,
		modTime:    result.Modified.Time,
		delTime:    nil,
		collection: dir,
		sha256sum:  "",
	}, nil
}

func (f filesystem) DeleteRecursive(r Resource, hardDelete bool) (uuid.UUIDs, error) {
	if r.Permission() < PermissionReadWrite {
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
	if r.Name() == name {
		return nil, nil
	}
	if r.ParentID() == nil {
		return nil, ErrInsufficientPermissions
	}
	parent, err := f.ResourceByID(*r.ParentID())
	if err != nil {
		return nil, err
	}
	if parent.Permission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	if r, err := f.db.UpdateResourceName(f.ctx, db.UpdateResourceNameParams{ID: r.ID(), Name: name}); err != nil {
		return nil, err
	} else {
		return resource{
			id:         r.ID,
			parentID:   r.Parent,
			permission: 0, // TODO: set correctly
			name:       r.Name,
			size:       r.Size.Int64,
			modTime:    r.Modified.Time,
			delTime:    &r.Deleted.Time,
			collection: r.Dir,
			sha256sum:  r.Sha256sum.String,
		}, nil
	}
}

func (f filesystem) UpdateParent(r Resource, parent uuid.UUID) (Resource, error) {
	if r.ParentID() == nil {
		return nil, ErrInsufficientPermissions
	}
	if *r.ParentID() == parent {
		return nil, nil
	}
	oldParent, err := f.ResourceByID(*r.ParentID())
	if err != nil {
		return nil, err
	}
	if oldParent.Permission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	newParent, err := f.ResourceByID(parent)
	if err != nil {
		return nil, err
	}
	if newParent.Permission() < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	if r, err := f.db.UpdateResourceParent(f.ctx, db.UpdateResourceParentParams{ID: r.ID(), Parent: parent}); err != nil {
		return nil, err
	} else {
		return resource{
			id:         r.ID,
			parentID:   r.Parent,
			permission: 0, // TODO: set correctly
			name:       r.Name,
			size:       r.Size.Int64,
			modTime:    r.Modified.Time,
			delTime:    &r.Deleted.Time,
			collection: r.Dir,
			sha256sum:  r.Sha256sum.String,
		}, nil
	}
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

// func (f filesystem) GetPermissionsLocal(r Resource) (map[int32]Permission, error) {
// 	if r.Permission() < PermissionReadWriteShare {
// 		return nil, ErrInsufficientPermissions
// 	}
// 	p, err := f.db.GetLocalPermissionsForResource(f.ctx, r.ID())
// 	if err != nil {
// 		return nil, err
// 	}
// 	res := make(map[int32]Permission, len(p))
// 	for _, p := range p {
// 		res[p.UserID] = p.Permission
// 	}
// 	return res, nil
// }

// func (f filesystem) GetPermissionsInherited(r Resource) (map[int32]Permission, error) {
// 	if r.Permission() < PermissionReadWriteShare {
// 		return nil, ErrInsufficientPermissions
// 	}
// 	if r.ParentID() == nil {
// 		return nil, nil
// 	}

// 	p, err := f.db.GetInheritedPermissionsForResource(f.ctx, *r.ParentID())
// 	if err != nil {
// 		return nil, err
// 	}
// 	res := make(map[int32]Permission, len(p))
// 	for _, p := range p {
// 		res[p.UserID] = p.Permission
// 	}
// 	return res, nil
// }
