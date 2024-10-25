package fs

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) CreateResourceByPath(path string, dir, recursive bool) (Resource, error) {
	path = strings.TrimRight(path, "/")
	index := strings.LastIndex(path, "/")
	name := path[index+1:]
	parentPath := path[0:index]
	parent, err := f.ResourceByPath(parentPath)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			if recursive {
				// TODO: this is very inefficient, but used only directly from the command line
				parent, err = f.CreateResourceByPath(parentPath, true, true)
			} else {
				err = ErrParentNotFound
			}
		}
		if err != nil {
			return Resource{}, err
		}
	}
	return parent.CreateMemberResource(name, uuid.Nil, dir)
}

func (r Resource) CreateMemberResource(name string, id uuid.UUID, dir bool) (Resource, error) {
	if !r.Dir {
		return Resource{}, ErrResourceNotCollection
	}
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}
	if name == "" || CheckNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}
	if id == uuid.Nil {
		id, _ = uuid.NewUUID()
	}
	var result db.Resource
	err := r.f.db.WithTx(r.f.ctx, func(d *db.DbHandler) error {
		var err error
		parent := r.ID
		if result, err = d.CreateResource(r.f.ctx, db.CreateResourceParams{ID: id, Parent: &parent, Name: name, Dir: dir}); err != nil {
			if strings.Contains(err.Error(), "unique_member_resource_name") {
				return ErrResourceNameConflict
			}
			if strings.Contains(err.Error(), "resources_pkey") {
				return ErrResourceIDConflict
			}
			return err
		}
		return d.UpdateResourceModified(r.f.ctx, parent)
	})
	if err != nil {
		return Resource{}, err
	}
	out, err := r.f.cs.OpenWrite(id, nil, nil)
	if err == nil {
		err = out.Close()
	}
	if err != nil {
		return Resource{}, err
	}

	p, err := MergePermissionStrings(r.InheritedPermissions, r.Permissions)
	if err != nil {
		return Resource{}, err
	}
	var deleted *time.Time
	if result.Deleted.Valid {
		deleted = &result.Deleted.Time
	}
	path := r.Path + "/" + result.Name
	if r.Path == "/" {
		path = result.Name
	}
	return Resource{
		f:                    r.f,
		ID:                   result.ID,
		ParentID:             result.Parent,
		Name:                 result.Name,
		Created:              result.Created.Time,
		Modified:             result.Modified.Time,
		Deleted:              deleted,
		Dir:                  result.Dir,
		ContentSize:          result.ContentSize,
		ContentType:          result.ContentType,
		ContentSHA256:        result.ContentSha256,
		Permissions:          string(result.Permissions),
		Path:                 path,
		UserPermissions:      r.UserPermissions,
		InheritedPermissions: p,
	}, nil
}
