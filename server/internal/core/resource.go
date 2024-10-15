package core

import (
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	ID                   uuid.UUID  `json:"id"`
	ParentID             *uuid.UUID `json:"parent"`
	Name                 string     `json:"name"`
	Dir                  bool       `json:"dir"`
	Modified             time.Time  `json:"modified"`
	Deleted              *time.Time `json:"deleted"`
	ContentSize          int64      `json:"csize"`
	ContentType          string     `json:"ctype"`
	ContentSHA256        string     `json:"csha256"`
	Permissions          string     `json:"permissions"`
	UserPermissions      int32      `json:"-"`
	InheritedPermissions string     `json:"-"`
}
