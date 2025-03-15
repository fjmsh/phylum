package fs

import (
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	f              filesystem
	id             uuid.UUID
	parentID       *uuid.UUID
	name           string
	dir            bool
	created        time.Time
	modified       time.Time
	deleted        *time.Time
	contentLength  int64
	contentType    string
	contentSHA256  string
	permissions    []byte
	grants         []byte
	userPermission Permission
}

func (r Resource) ID() uuid.UUID         { return r.id }
func (r Resource) ParentID() *uuid.UUID  { return r.parentID }
func (r Resource) Name() string          { return r.name }
func (r Resource) Dir() bool             { return r.dir }
func (r Resource) Created() time.Time    { return r.created }
func (r Resource) Modified() time.Time   { return r.modified }
func (r Resource) Deleted() *time.Time   { return r.deleted }
func (r Resource) ContentLength() int64  { return r.contentLength }
func (r Resource) ContentSHA256() string { return r.contentSHA256 }
func (r Resource) ContentType() string   { return r.contentType }
func (r Resource) Permissions() []byte   { return r.permissions }
func (r Resource) Grants() []byte        { return r.grants }

func (r Resource) hasPermission(p Permission) bool {
	return r.userPermission&p != 0
}
