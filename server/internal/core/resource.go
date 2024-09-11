package core

import (
	"mime"
	"path/filepath"
	"time"

	"github.com/google/uuid"
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
	sha256sum  string
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
	return r.sha256sum
}

func (r resource) ContentType() string {
	if r.IsDir() {
		return ""
	}
	mimeType := mime.TypeByExtension(filepath.Ext(r.name))
	if mimeType != "" {
		return mimeType
	}
	return "application/octet-stream"
}
