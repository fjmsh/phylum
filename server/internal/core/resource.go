package core

import (
	"errors"
	"fmt"
	"mime"
	"path/filepath"
	"time"

	"github.com/google/uuid"
)

const (
	PermissionReadOnly  = 1
	PermissionReadWrite = 3
	PermissionAdmin     = 127
)

var (
	ErrInsufficientPermissions    = errors.New("insufficient permissions")
	ErrCannotGrantOwnerPermission = errors.New("cannot grant owner permission")
	ErrResourceNotCollection      = errors.New("cannot add member to non-collection resource")
	ErrCannotReparentRootResource = errors.New("cannot reparent root resource")
	ErrCannotReparentToRoot       = errors.New("cannot reparent resource to root")
)

type Resource interface {
	ID() uuid.UUID
	ParentID() *uuid.UUID
	Name() string
	Size() int64
	Permission() int32
	ModTime() time.Time
	DelTime() *time.Time
	IsDir() bool
	ETag() string
	ContentType() string
}

type resource struct {
	id         uuid.UUID
	permission int32
	parentID   *uuid.UUID
	name       string
	size       int64
	collection bool
	modTime    time.Time
	delTime    *time.Time
	etag       string
}

func (r resource) ID() uuid.UUID { return r.id }

func (r resource) Permission() int32 { return r.permission }

func (r resource) ParentID() *uuid.UUID { return r.parentID }

func (r resource) Name() string { return r.name }

func (r resource) Size() int64 { return r.size }

func (r resource) ModTime() time.Time { return r.modTime }

func (r resource) DelTime() *time.Time { return r.delTime }

func (r resource) IsDir() bool { return r.collection }

func (r resource) ETag() string {
	if r.etag != "" {
		return r.etag
	}
	// The Apache http 2.4 web server by default concatenates the
	// modification time and size of a file.
	return fmt.Sprintf(`"%x%x"`, r.modTime.UnixMilli(), r.size)
}

func (r resource) ContentType() string {
	mimeType := mime.TypeByExtension(filepath.Ext(r.name))
	if mimeType != "" {
		return mimeType
	}
	return "application/octet-stream"
}
