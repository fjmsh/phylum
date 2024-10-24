package public

import (
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	id            uuid.UUID
	name          string
	dir           bool
	created       time.Time
	modified      time.Time
	contentSize   int64
	contentType   string
	contentSHA256 string
}

func (r Resource) MID() uuid.UUID         { return r.id }
func (r Resource) MName() string          { return r.name }
func (r Resource) MDir() bool             { return r.dir }
func (r Resource) MCreated() time.Time    { return r.created }
func (r Resource) MModified() time.Time   { return r.modified }
func (r Resource) MContentSize() int64    { return r.contentSize }
func (r Resource) MContentSHA256() string { return r.contentSHA256 }
func (r Resource) MContentType() string   { return r.contentType }
