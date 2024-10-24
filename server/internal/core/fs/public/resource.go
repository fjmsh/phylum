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

func (r Resource) Name() string          { return r.name }
func (r Resource) Dir() bool             { return r.dir }
func (r Resource) Created() time.Time    { return r.created }
func (r Resource) Modified() time.Time   { return r.modified }
func (r Resource) ContentSize() int64    { return r.contentSize }
func (r Resource) ContentSHA256() string { return r.contentSHA256 }
func (r Resource) ContentType() string   { return r.contentType }
