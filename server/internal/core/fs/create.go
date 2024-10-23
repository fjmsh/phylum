package fs

import (
	"errors"
	"strings"

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
	id, _ := uuid.NewUUID()
	return f.CreateMemberResource(parent, id, name, dir)
}

func (f filesystem) CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error) {
	if !r.Dir {
		return Resource{}, ErrResourceNotCollection
	}
	if !r.hasPermission(PermissionWrite) {
		return Resource{}, ErrInsufficientPermissions
	}
	if name == "" || CheckNameInvalid(name) {
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
		return d.UpdateResourceModified(f.ctx, parent)
	})
	if err != nil {
		return Resource{}, err
	}
	// TODO: #badbehavior Inherited permissions should include r.Permissions as well
	return ResourceFromDB(result, r.UserPermissions, r.Path+"/"+result.Name, r.InheritedPermissions), nil
}
