package core

import (
	"context"
	"crypto/sha256"
	"io"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type DiskUsageInfo struct {
	TotalSize int64
	Entities  int64
	Files     int64
	Dirs      int64
}

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
	DiskUsage(r Resource) (DiskUsageInfo, error)
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
		err = ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}
	return f.ResourceByID(res.ID)
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: f.rootID, ResourceID: id, Username: f.username})
	// TODO: verify found
	if err == pgx.ErrNoRows || !res.Found || res.UserPermission == 0 {
		err = ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}

	var delTime *time.Time
	if res.Deleted.Valid {
		delTime = &res.Deleted.Time
	}
	return Resource{
		ID:            res.ID,
		ParentID:      res.Parent,
		Name:          res.Name,
		Dir:           res.Dir,
		Modified:      res.Modified.Time,
		Deleted:       delTime,
		ContentSize:   res.ContentSize,
		ContentType:   res.ContentType,
		ContentSHA256: res.ContentSha256,
		Permissions:   string(res.Permissions),
		// Definitely Needed
		UserPermissions:      res.UserPermission,
		InheritedPermissions: string(res.InheritedPermissions),
	}, nil
}
func (f filesystem) OpenRead(r Resource, start, length int64) (io.ReadCloser, error) {
	if r.UserPermissions < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenRead(r.ID, start, length)
}

func (f filesystem) OpenWrite(r Resource) (io.WriteCloser, error) {
	if r.UserPermissions < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	return f.cs.OpenWrite(r.ID, sha256.New, func(len int, sum, mime string) error {
		return f.db.UpdateResourceContents(f.ctx, db.UpdateResourceContentsParams{
			ID:            r.ID,
			ContentType:   mime,
			ContentSize:   int64(len),
			ContentSha256: sum,
		})
	})
}

func (f filesystem) ReadDir(r Resource) ([]Resource, error) {
	if r.UserPermissions < PermissionReadOnly {
		return nil, ErrInsufficientPermissions
	}
	if !r.Dir {
		return nil, ErrResourceNotCollection
	}
	children, err := f.db.ReadDir(f.ctx, db.ReadDirParams{
		ID:          r.ID,
		IncludeRoot: false,
		Recursive:   false,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Resource, len(children))
	for i, c := range children {
		result[i] = Resource{
			ID:            c.ID,
			ParentID:      c.Parent,
			Name:          c.Name,
			Modified:      c.Modified.Time,
			Deleted:       nil,
			Dir:           c.Dir,
			ContentSize:   c.ContentSize,
			ContentType:   c.ContentType,
			ContentSHA256: c.ContentSha256,
			Permissions:   string(c.Permissions),
			// Not Needed
			// UserPermissions: 0,
			// InheritedPermissions: "",
		}
	}
	return result, nil
}

func (f filesystem) CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error) {
	if !r.Dir {
		return Resource{}, ErrResourceNotCollection
	}
	if r.UserPermissions < PermissionReadWrite {
		return Resource{}, ErrInsufficientPermissions
	}
	if name == "" || checkNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}
	var result db.Resource
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		parent := r.ID
		if result, err = d.CreateResource(f.ctx, db.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			if strings.Contains(err.Error(), "resources_pkey") {
				return ErrResourceIDConflict
			}
			return err
		}
		return d.UpdateResourceModified(f.ctx, r.ID)
	})
	if err != nil {
		return Resource{}, err
	}
	return Resource{
		ID:              id,
		ParentID:        result.Parent,
		Name:            result.Name,
		Dir:             dir,
		ContentSize:     0,
		Modified:        result.Modified.Time,
		Deleted:         nil,
		ContentSHA256:   "",
		Permissions:     string(result.Permissions),
		UserPermissions: r.UserPermissions,
		// Not Needed
		// InheritedPermissions: "",
	}, nil
}

func (f filesystem) DeleteRecursive(r Resource, hardDelete bool) (uuid.UUIDs, error) {
	if r.UserPermissions < PermissionReadWrite {
		return nil, ErrInsufficientPermissions
	}
	// TODO: versioning
	var ids uuid.UUIDs
	err := f.db.WithTx(f.ctx, func(d *db.DbHandler) error {
		var err error
		if hardDelete {
			ids, err = d.HardDeleteRecursive(f.ctx, r.ID)
			if err != nil {
				return err
			}
			errors := f.cs.DeleteAll(ids)
			for err := range errors {
				logrus.Warn(err)
			}
		} else {
			if ids, err = d.DeleteRecursive(f.ctx, r.ID); err != nil {
				return err
			}
		}

		parent := r.ParentID
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
	if r, err := f.db.UpdateResourceName(f.ctx, db.UpdateResourceNameParams{ID: r.ID, Name: name}); err != nil {
		return Resource{}, err
	} else {
		return Resource{
			ID:            r.ID,
			ParentID:      r.Parent,
			Name:          r.Name,
			Modified:      r.Modified.Time,
			Deleted:       &r.Deleted.Time,
			Dir:           r.Dir,
			ContentSize:   r.ContentSize,
			ContentType:   r.ContentType,
			ContentSHA256: r.ContentSha256,
			Permissions:   string(r.Permissions),
			// Not Needed
			// UserPermissions: 0,
			// InheritedPermissions: "",
		}, nil
	}
}

func (f filesystem) Move(r Resource, name string, parent *uuid.UUID) (Resource, error) {
	if r.ParentID == nil {
		return Resource{}, ErrInsufficientPermissions
	}
	if name == r.Name {
		name = ""
	}
	if checkNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}
	if parent == r.ParentID {
		parent = nil
	}

	// Check source directory permissions
	oldParent, err := f.ResourceByID(*r.ParentID)
	if err != nil {
		return Resource{}, err
	}
	if oldParent.UserPermissions < PermissionReadWrite {
		return Resource{}, ErrInsufficientPermissions
	}

	// Check target directory permissions (if applicable)
	if parent != nil {
		newParent, err := f.ResourceByID(*parent)
		if err != nil {
			return Resource{}, err
		}
		if newParent.UserPermissions < PermissionReadWrite {
			return Resource{}, ErrInsufficientPermissions
		}

		if res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: r.ID, ResourceID: *parent, Username: f.username}); err != nil || res.Found {
			return Resource{}, ErrResourceMoveTargetSubdirectory
		}
	}
	if r, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID, Name: name, Parent: parent}); err != nil {
		if strings.Contains(err.Error(), "unique_member_resource_name") {
			return Resource{}, ErrResourceNameConflict
		}
		return Resource{}, err
	} else {
		return Resource{
			ID:            r.ID,
			ParentID:      r.Parent,
			Name:          r.Name,
			Modified:      r.Modified.Time,
			Deleted:       &r.Deleted.Time,
			Dir:           r.Dir,
			ContentSize:   r.ContentSize,
			ContentType:   r.ContentType,
			ContentSHA256: r.ContentSha256,
			Permissions:   string(r.Permissions),
			// Not Needed
			// UserPermissions:      0,
			// InheritedPermissions: "",
		}, nil
	}
}

func (f filesystem) DiskUsage(r Resource) (DiskUsageInfo, error) {
	if info, err := f.db.DiskUsage(f.ctx, r.ID); err != nil {
		return DiskUsageInfo{}, err
	} else {
		return DiskUsageInfo{
			TotalSize: info.Size,
			Entities:  info.Entities,
			Files:     info.Files,
			Dirs:      info.Dirs,
		}, nil
	}
}

func (f filesystem) UpdatePermissions(r Resource, username string, permission Permission) error {
	if r.UserPermissions < PermissionReadWriteShare {
		return ErrInsufficientPermissions
	}
	if permission > PermissionReadWriteShare {
		permission = PermissionReadWriteShare
	}

	return f.db.UpdatePermissionsForResource(f.ctx, db.UpdatePermissionsForResourceParams{
		ResourceID: r.ID,
		Username:   username,
		Permission: permission,
	})
}

func checkNameInvalid(s string) bool {
	return strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
