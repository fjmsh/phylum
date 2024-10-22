package fs

import (
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
)

type Resource struct {
	ID                   uuid.UUID  `json:"id"`
	ParentID             *uuid.UUID `json:"parent"`
	Name                 string     `json:"name"`
	Dir                  bool       `json:"dir"`
	Created              time.Time  `json:"created"`
	Modified             time.Time  `json:"modified"`
	Deleted              *time.Time `json:"deleted"`
	ContentSize          int64      `json:"csize"`
	ContentType          string     `json:"ctype"`
	ContentSHA256        string     `json:"csha256"`
	Permissions          string     `json:"permissions"`
	Path                 string     `json:"-"`
	UserPermissions      int32      `json:"-"`
	InheritedPermissions string     `json:"-"`
}

func ResourceFromDB(r db.Resource, userPermissions int32, path, inheritedPermissions string) Resource {
	var deleted *time.Time
	if r.Deleted.Valid {
		deleted = &r.Deleted.Time
	}
	return Resource{
		ID:                   r.ID,
		ParentID:             r.Parent,
		Name:                 r.Name,
		Created:              r.Created.Time,
		Modified:             r.Modified.Time,
		Deleted:              deleted,
		Dir:                  r.Dir,
		ContentSize:          r.ContentSize,
		ContentType:          r.ContentType,
		ContentSHA256:        r.ContentSha256,
		Permissions:          string(r.Permissions),
		Path:                 path,
		UserPermissions:      userPermissions,
		InheritedPermissions: inheritedPermissions,
	}
}
