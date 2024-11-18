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
	if !r.Dir() {
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
		parent := r.ID()
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
	if err == ErrResourceIDConflict {
		return r.f.ResourceByID(id)
	}
	if err != nil {
		return Resource{}, err
	}
	if !r.Dir() {
		out, err := r.f.cs.OpenWrite(id, nil, nil)
		if err == nil {
			err = out.Close()
		}
		if err != nil {
			return Resource{}, err
		}
	}

	info := ResourceInfoFromDBResource(result)
	if r.Path() == "/" {
		info.path = "/" + info.name
	} else {
		info.path = r.Path() + "/" + info.name
	}
	ancestry := make([]ResourceInfo, len(r.Ancestors)+1)
	copy(ancestry, r.Ancestors)
	ancestry = append(ancestry, r.Info)
	return Resource{
		f:              r.f,
		Ancestors:      ancestry,
		Info:           info,
		userPermission: r.userPermission,
	}, nil
}

func ResourceInfoFromDBResource(r db.Resource) ResourceInfo {
	var delTime *time.Time
	if r.Deleted.Valid {
		delTime = &r.Deleted.Time
	}
	return ResourceInfo{
		id:            r.ID,
		parentID:      r.Parent,
		name:          r.Name,
		dir:           r.Dir,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		deleted:       delTime,
		contentSize:   r.ContentSize,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
		permissions:   r.Permissions,
	}
}
