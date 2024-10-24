package public

import (
	"time"

	"github.com/google/uuid"
)

type Resource struct {
	ID            uuid.UUID
	Name          string
	Dir           bool
	Created       time.Time
	Modified      time.Time
	Deleted       *time.Time
	ContentSize   int64
	ContentSHA256 string
}
