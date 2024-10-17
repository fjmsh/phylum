package core

import (
	"context"
	"crypto/sha256"
	"io"
	"strings"
	"time"

	"errors"

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
	WithDb(db *db.DbHandler) FileSystem
	RunInTx(fn func(FileSystem) error) error
	RootID() uuid.UUID
	ResourceByPath(path string) (Resource, error)
	ResourceByID(id uuid.UUID) (Resource, error)
	OpenRead(r Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(r Resource) (io.WriteCloser, error)
	ReadDir(r Resource) ([]Resource, error)
	CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error)
	DeleteChildRecursive(r Resource, name string, hardDelete bool) error
	DeleteRecursive(r Resource, hardDelete bool) (uuid.UUIDs, error)
	Move(r Resource, parentID uuid.UUID, name string, overwrite bool) (Resource, error)
	Copy(r Resource, target Resource, ID uuid.UUID, name string, recursive, overwrite bool) (Resource, error)
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
	return f.withDb(db)
}
func (f filesystem) withDb(db *db.DbHandler) filesystem {
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
	r, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: f.rootID, ResourceID: id, Username: f.username})
	// TODO: verify found
	if err == pgx.ErrNoRows || !r.Found || r.UserPermission == 0 {
		err = ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}

	var delTime *time.Time
	if r.Deleted.Valid {
		delTime = &r.Deleted.Time
	}
	return Resource{
		ID:            r.ID,
		ParentID:      r.Parent,
		Name:          r.Name,
		Dir:           r.Dir,
		Created:       r.Created.Time,
		Modified:      r.Modified.Time,
		Deleted:       delTime,
		ContentSize:   r.ContentSize,
		ContentType:   r.ContentType,
		ContentSHA256: r.ContentSha256,
		Permissions:   string(r.Permissions),
		// Definitely Needed
		UserPermissions:      r.UserPermission,
		InheritedPermissions: string(r.InheritedPermissions),
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
			Created:       c.Created.Time,
			Modified:      c.Modified.Time,
			Deleted:       nil, // Query will not return deleted results
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
		ID:              result.ID,
		ParentID:        result.Parent,
		Name:            result.Name,
		Dir:             result.Dir,
		Created:         result.Created.Time,
		Modified:        result.Modified.Time,
		Deleted:         nil, // Cannot be deleted when created
		ContentType:     result.ContentType,
		ContentSize:     result.ContentSize,
		ContentSHA256:   result.ContentSha256,
		Permissions:     string(result.Permissions),
		UserPermissions: r.UserPermissions,
		// Not Needed
		// InheritedPermissions: "",
	}, nil
}

func (f filesystem) DeleteChildRecursive(r Resource, name string, hardDelete bool) error {
	if result, err := f.db.ChildResourceByName(f.ctx, db.ChildResourceByNameParams{Parent: r.ID, Name: name}); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrResourceNotFound
		}
		return err
	} else {
		child := Resource{
			ID:              result.ID,
			ParentID:        result.Parent,
			Name:            result.Name,
			Dir:             result.Dir,
			Created:         result.Created.Time,
			Modified:        result.Modified.Time,
			Deleted:         nil,
			ContentType:     result.ContentType,
			ContentSize:     result.ContentSize,
			ContentSHA256:   result.ContentSha256,
			Permissions:     string(result.Permissions),
			UserPermissions: r.UserPermissions,
			// Not Needed
			// InheritedPermissions: "",
		}
		_, err := f.DeleteRecursive(child, hardDelete)
		return err
	}
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
		var deleted *time.Time
		if r.Deleted.Valid {
			deleted = &r.Deleted.Time
		}
		return Resource{
			ID:            r.ID,
			ParentID:      r.Parent,
			Name:          r.Name,
			Created:       r.Created.Time,
			Modified:      r.Modified.Time,
			Deleted:       deleted,
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

func (f filesystem) Move(r Resource, parentID uuid.UUID, name string, overwrite bool) (Resource, error) {
	if r.ParentID == nil {
		return Resource{}, ErrInsufficientPermissions
	}
	if checkNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}

	// Check source directory permissions
	parent, err := f.ResourceByID(*r.ParentID)
	if err != nil {
		return Resource{}, err
	}
	if parent.UserPermissions < PermissionReadWrite {
		return Resource{}, ErrInsufficientPermissions
	}

	// Check destParent directory permissions (if applicable)
	if parentID == uuid.Nil {
		parentID = *r.ParentID
	}
	destParent, err := f.ResourceByID(parentID)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, err
	}
	if destParent.UserPermissions < PermissionReadWrite {
		return Resource{}, ErrInsufficientPermissions
	}
	if res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: r.ID, ResourceID: parentID, Username: f.username}); err != nil || res.Found {
		return Resource{}, ErrResourceMoveTargetSubdirectory
	}
	result := Resource{}

	return result, f.db.WithTx(f.ctx, func(dbh *db.DbHandler) error {
		f = f.withDb(dbh)
		if overwrite {
			f.DeleteChildRecursive(destParent, name, false)
		}
		if r, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID, Name: name, Parent: parentID}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			return err
		} else {
			var deleted *time.Time
			if r.Deleted.Valid {
				deleted = &r.Deleted.Time
			}
			result = Resource{
				ID:            r.ID,
				ParentID:      r.Parent,
				Name:          r.Name,
				Created:       r.Created.Time,
				Modified:      r.Modified.Time,
				Deleted:       deleted,
				Dir:           r.Dir,
				ContentSize:   r.ContentSize,
				ContentType:   r.ContentType,
				ContentSHA256: r.ContentSha256,
				Permissions:   string(r.Permissions),
				// Not Needed
				// UserPermissions:      0,
				// InheritedPermissions: "",
			}
			return nil
		}
	})
}

func (f filesystem) Copy(src, target Resource, id uuid.UUID, destName string, recursive, overwrite bool) (dest Resource, e error) {
	if checkNameInvalid(destName) {
		e = ErrResourceNameInvalid
		return
	}

	// Check source directory permissions
	if src.UserPermissions < PermissionReadOnly {
		e = ErrInsufficientPermissions
		return
	}

	// Check dest directory permissions
	if target.UserPermissions < PermissionReadWrite {
		e = ErrInsufficientPermissions
		return
	}

	copy := make(map[uuid.UUID]uuid.UUID)

	e = f.db.WithTx(f.ctx, func(dbh *db.DbHandler) error {
		f = f.withDb(dbh)
		if overwrite {
			if err := f.DeleteChildRecursive(target, destName, false); err != nil && !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		var tree []db.ReadDirRow
		if recursive && src.Dir {
			var err error
			tree, err = f.db.ReadDir(f.ctx, db.ReadDirParams{ID: src.ID, IncludeRoot: false, Recursive: true})
			if err != nil {
				return err
			}
		}
		dest, err := f.CreateMemberResource(target, id, destName, src.Dir)
		if err != nil {
			return err
		}
		if !src.Dir {
			copy[dest.ID] = src.ID
		}

		ids := make(map[string]uuid.UUID)
		ids[""] = dest.ID
		for _, src := range tree {
			id := uuid.New()
			parent := ids[src.Path[0:strings.LastIndex(src.Path, "/")]]

			if _, err := dbh.CreateResource(f.ctx, db.CreateResourceParams{ID: id, Parent: &parent, Name: src.Name, Dir: src.Dir}); err != nil {
				if strings.Contains(err.Error(), "unique_member_resource_name") {
					return ErrResourceNameConflict
				}
				if strings.Contains(err.Error(), "resources_pkey") {
					return ErrResourceIDConflict
				}
				return err
			} else {
				if src.Dir {
					ids[src.Path] = id
				} else {
					copy[src.ID] = id
				}
			}
		}

		return nil
	})

	return
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

	if permission == 0 {
		return f.db.RemoveUserPermissionForResource(f.ctx, db.RemoveUserPermissionForResourceParams{
			ResourceID: r.ID,
			Username:   username,
		})
	}
	return f.db.UpdateUserPermissionsForResource(f.ctx, db.UpdateUserPermissionsForResourceParams{
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
