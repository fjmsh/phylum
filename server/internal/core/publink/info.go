package publink

import (
	"time"

	"github.com/google/uuid"
)

type Info struct {
	ID          int32      `json:"id"`
	Name        string     `json:"name"`
	Created     time.Time  `json:"created"`
	Deleted     *time.Time `json:"deleted"`
	CreatedBy   string     `json:"creator"`
	Root        uuid.UUID  `json:"root"`
	Accessed    int32      `json:"accessed"`
	MaxAccesses int32      `json:"max_accesses"`
	Protected   bool       `json:"protected"`
	Expires     *time.Time `json:"expires"`
}
