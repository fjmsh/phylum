package fs

import (
	"errors"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) CreateResourceByPath(path string, dir bool) (Resource, error) {
	path = strings.TrimRight(path, "/")
	index := strings.LastIndex(path, "/")
	name := path[index+1:]
	parentPath := path[0:index]
	parent, err := f.ResourceByPath(parentPath)
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return Resource{}, err
	}
	return f.CreateMemberResource(parent, uuid.New(), name, dir)
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
		// Path: r.Path + "/" + result.Name,
		// InheritedPermissions: "",
	}, nil
}
