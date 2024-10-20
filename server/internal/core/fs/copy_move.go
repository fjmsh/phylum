package fs

import (
	"errors"
	"io"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func (f filesystem) Move(r Resource, target string, overwrite bool) (Resource, error) {
	if r.ParentID == nil {
		return Resource{}, ErrInsufficientPermissions
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
	destParent, destName, err := f.targetByPathOrUUID(r, target)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, err
	}
	if destParent.UserPermissions < PermissionReadWrite {
		return Resource{}, ErrInsufficientPermissions
	}
	if res, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: r.ID, ResourceID: destParent.ID, Username: f.username}); err != nil || res.Found {
		return Resource{}, ErrResourceMoveTargetSubdirectory
	}
	result := Resource{}

	return result, f.db.WithTx(f.ctx, func(dbh *db.DbHandler) error {
		f = f.withDb(dbh)
		if overwrite {
			f.DeleteChildRecursive(destParent, destName, false)
		}
		if r, err := f.db.UpdateResourceNameParent(f.ctx, db.UpdateResourceNameParentParams{ID: r.ID, Name: destName, Parent: destParent.ID}); err != nil {
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

func (f filesystem) Copy(src Resource, target string, id uuid.UUID, recursive, overwrite bool) (dest Resource, e error) {
	// Check source directory permissions
	if src.UserPermissions < PermissionReadOnly {
		e = ErrInsufficientPermissions
		return
	}

	// Check dest directory permissions
	destParent, destName, err := f.targetByPathOrUUID(src, target)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, err
	}
	if destParent.UserPermissions < PermissionReadWrite {
		e = ErrInsufficientPermissions
		return
	}

	var tree []db.ReadDirRow
	if recursive && src.Dir {
		var err error
		tree, err = f.db.ReadDir(f.ctx, db.ReadDirParams{ID: src.ID, IncludeRoot: false, Recursive: true})
		if err != nil {
			return Resource{}, err
		}
	}
	create := make([]db.CreateResourcesParams, 0, len(tree))
	copy := make(map[uuid.UUID]uuid.UUID)
	ids := make(map[string]uuid.UUID)
	if src.Dir {
		ids[""] = id
	} else {
		copy[src.ID] = id
	}

	for _, src := range tree {
		id := uuid.New()
		parent := ids[src.Path[0:strings.LastIndex(src.Path, "/")]]

		create = append(create, db.CreateResourcesParams{
			ID:            id,
			Parent:        parent,
			Name:          src.Name,
			Dir:           src.Dir,
			ContentType:   src.ContentType,
			ContentSha256: src.ContentSha256,
		})

		if src.Dir {
			ids[src.Path] = id
		} else {
			copy[src.ID] = id
		}
	}

	e = f.db.WithTx(f.ctx, func(dbh *db.DbHandler) error {
		f := f.withDb(dbh)
		if overwrite {
			if err := f.DeleteChildRecursive(destParent, destName, false); err != nil && !errors.Is(err, ErrResourceNotFound) {
				return err
			}
		}
		dest, err = f.CreateMemberResource(destParent, id, destName, src.Dir)
		if err != nil {
			return err
		}
		_, err := dbh.CreateResources(f.ctx, create)
		return err
	})

	if e == nil {
		func() {
			for k, v := range copy {
				if _, err := f.copyContents(k, v); err != nil {
					logrus.Warn("unable to copy " + k.String() + " to " + v.String() + ": " + err.Error())
				}
			}

		}()
	}

	return
}

// targetByPathOrUUID splits a target path or uuid into its constituent components
// `pathOrUUID` can be of the following formats:
// 1. absolute path beginning with '/'
// 2. uuid+name separated by ':'
// For the latter, if either uuid or name is not provided then it is filled in from `src`
func (f filesystem) targetByPathOrUUID(src Resource, pathOrUUID string) (Resource, string, error) {
	index := strings.Index(pathOrUUID, ":")
	if index == -1 {
		if pathOrUUID[0] != '/' {
			return Resource{}, "", ErrResourcePathInvalid
		}
		path := strings.TrimRight(pathOrUUID, "/")
		// if dest, err := f.ResourceByPath(path); err == nil {
		// 	return dest, src.Name, nil
		// } else {
		index := strings.LastIndex(path, "/")
		name := path[index+1:]
		path = path[0:index]
		if parent, err := f.ResourceByPath(path); err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, "", err
		} else if checkNameInvalid(name) {
			return Resource{}, "", ErrResourceNameInvalid
		} else {
			return parent, name, nil
		}
		// }
	}
	var parent Resource
	if index == 0 {
		parent = src
	} else {
		if id, err := uuid.Parse(pathOrUUID[0:index]); err != nil {
			return Resource{}, "", err
		} else if res, err := f.ResourceByID(id); err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, "", err
		} else {
			parent = res
		}

	}

	name := pathOrUUID[index+1:]
	if name == "" {
		name = src.Name
	} else if checkNameInvalid(name) {
		return Resource{}, "", ErrResourceNameInvalid
	}

	return parent, name, nil
}

func (f filesystem) copyContents(k, v uuid.UUID) (int64, error) {
	src, err := f.ResourceByID(k)
	if err != nil {
		return 0, errors.New("unable to get " + k.String() + ": " + err.Error())
	}
	dest, err := f.ResourceByID(v)
	if err != nil {
		return 0, errors.New("unable to get " + v.String() + ": " + err.Error())
	}
	in, err := f.OpenRead(src, 0, -1)
	if err != nil {
		return 0, errors.New("Unable to open " + k.String() + ": " + err.Error())
	}
	defer in.Close()
	out, err := f.OpenWrite(dest)
	if err != nil {
		return 0, errors.New("Unable to open " + v.String() + ": " + err.Error())
	}
	defer out.Close()

	return io.Copy(out, in)
}
