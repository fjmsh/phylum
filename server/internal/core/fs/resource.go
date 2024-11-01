package fs

import (
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	f              filesystem
	Ancestry       []ResourceInfo `json:"ancestry"`
	UserPermission Permission     `json:"perm"`
}

type ResourceInfo struct {
	ID            uuid.UUID  `json:"id"`
	ParentID      *uuid.UUID `json:"parent"`
	Name          string     `json:"name"`
	Dir           bool       `json:"dir"`
	Created       time.Time  `json:"created"`
	Modified      time.Time  `json:"modified"`
	Deleted       *time.Time `json:"deleted"`
	ContentSize   int64      `json:"csize"`
	ContentType   string     `json:"ctype"`
	ContentSHA256 string     `json:"csha256"`
	Permissions   string     `json:"permissions"`
	Publinks      int        `json:"publinks"`
	Path          string     `json:"-"`
}

func (r Resource) Info() ResourceInfo      { return r.Ancestry[len(r.Ancestry)-1] }
func (r Resource) ID() uuid.UUID           { return r.Info().ID }
func (r Resource) ParentID() *uuid.UUID    { return r.Info().ParentID }
func (r Resource) FSName() string          { return r.Info().Name }
func (r Resource) FSDir() bool             { return r.Info().Dir }
func (r Resource) FSCreated() time.Time    { return r.Info().Created }
func (r Resource) FSModified() time.Time   { return r.Info().Modified }
func (r Resource) Deleted() *time.Time     { return r.Info().Deleted }
func (r Resource) FSContentSize() int64    { return r.Info().ContentSize }
func (r Resource) FSContentSHA256() string { return r.Info().ContentSHA256 }
func (r Resource) FSContentType() string   { return r.Info().ContentType }
func (r Resource) Publinks() int           { return r.Info().Publinks }
func (r Resource) FSPath() string          { return r.Info().Path }

func (r ResourceInfo) FSName() string          { return r.Name }
func (r ResourceInfo) FSDir() bool             { return r.Dir }
func (r ResourceInfo) FSCreated() time.Time    { return r.Created }
func (r ResourceInfo) FSModified() time.Time   { return r.Modified }
func (r ResourceInfo) FSContentSize() int64    { return r.ContentSize }
func (r ResourceInfo) FSContentSHA256() string { return r.ContentSHA256 }
func (r ResourceInfo) FSContentType() string   { return r.ContentType }
func (r ResourceInfo) FSPath() string          { return r.Path }
