package core

import (
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	ID                   uuid.UUID  `json:"id"`
	ParentID             *uuid.UUID `json:"parent"`
	Name                 string     `json:"name"`
	Size                 int64      `json:"size"`
	Dir                  bool       `json:"dir"`
	Modified             time.Time  `json:"modified"`
	Deleted              *time.Time `json:"deleted"`
	ContentType          string     `json:"ctype"`
	ETag                 string     `json:"etag"`
	Permissions          string     `json:"permissions"`
	UserPermissions      int32      `json:"-"`
	InheritedPermissions string     `json:"-"`
}
