package fs

import (
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	f                    filesystem
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
	Publinks             int        `json:"publinks"`
	Path                 string     `json:"path"`
	UserPermission       Permission `json:"perm"`
	InheritedPermissions string     `json:"inherited"`
}

func (r Resource) FSName() string          { return r.Name }
func (r Resource) FSPath() string          { return r.Path }
func (r Resource) FSDir() bool             { return r.Dir }
func (r Resource) FSCreated() time.Time    { return r.Created }
func (r Resource) FSModified() time.Time   { return r.Modified }
func (r Resource) FSContentSize() int64    { return r.ContentSize }
func (r Resource) FSContentSHA256() string { return r.ContentSHA256 }
func (r Resource) FSContentType() string   { return r.ContentType }
