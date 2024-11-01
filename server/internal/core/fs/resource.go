package fs

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	f              filesystem
	Ancestry       []ResourceInfo `json:"ancestry"`
	UserPermission Permission     `json:"perm"`
}

type ResourceInfo struct {
	id            uuid.UUID
	parentID      *uuid.UUID
	name          string
	dir           bool
	created       time.Time
	modified      time.Time
	deleted       *time.Time
	contentSize   int64
	contentType   string
	contentSHA256 string
	permissions   []byte
	publinks      int
	path          string
}

func (r Resource) Last() *ResourceInfo   { return &r.Ancestry[len(r.Ancestry)-1] }
func (r Resource) ID() uuid.UUID         { return r.Last().id }
func (r Resource) ParentID() *uuid.UUID  { return r.Last().parentID }
func (r Resource) Name() string          { return r.Last().name }
func (r Resource) Dir() bool             { return r.Last().dir }
func (r Resource) Created() time.Time    { return r.Last().created }
func (r Resource) Modified() time.Time   { return r.Last().modified }
func (r Resource) Deleted() *time.Time   { return r.Last().deleted }
func (r Resource) ContentSize() int64    { return r.Last().contentSize }
func (r Resource) ContentSHA256() string { return r.Last().contentSHA256 }
func (r Resource) ContentType() string   { return r.Last().contentType }
func (r Resource) Publinks() int         { return r.Last().publinks }
func (r Resource) Path() string          { return r.Last().path }

func (r Resource) hasPermission(p Permission) bool {
	return r.UserPermission&p != 0
}

func (r Resource) FullPermissionsString() string {
	result := make(map[string]Permission)
	for _, i := range r.Ancestry {
		p := make(map[string]Permission)
		json.Unmarshal([]byte(i.permissions), &p)
		for k, v := range p {
			result[k] = result[k] | v
		}
	}
	res, err := json.Marshal(result)
	if err != nil {
		return err.Error()
	}
	return permissionJsonString(res)
}

func (r ResourceInfo) ID() uuid.UUID         { return r.id }
func (r ResourceInfo) ParentID() *uuid.UUID  { return r.parentID }
func (r ResourceInfo) Name() string          { return r.name }
func (r ResourceInfo) Dir() bool             { return r.dir }
func (r ResourceInfo) Created() time.Time    { return r.created }
func (r ResourceInfo) Modified() time.Time   { return r.modified }
func (r ResourceInfo) Deleted() *time.Time   { return r.deleted }
func (r ResourceInfo) ContentSize() int64    { return r.contentSize }
func (r ResourceInfo) ContentSHA256() string { return r.contentSHA256 }
func (r ResourceInfo) ContentType() string   { return r.contentType }
func (r ResourceInfo) Publinks() int         { return r.publinks }
func (r ResourceInfo) Path() string          { return r.path }

func (r ResourceInfo) PermissionsString() string {
	return permissionJsonString(r.permissions)
}
