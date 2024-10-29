package publink

import (
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
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

func InfoFromDB(d db.Publink) Info {
	var deleted *time.Time
	if d.Deleted.Valid {
		deleted = &d.Deleted.Time
	}
	var expires *time.Time
	if d.Expires.Valid {
		expires = &d.Expires.Time
	}
	return Info{
		ID:          d.ID,
		Name:        d.Name,
		Created:     d.Created.Time,
		Deleted:     deleted,
		CreatedBy:   d.CreatedBy,
		Root:        d.Root,
		Accessed:    d.Accessed,
		MaxAccesses: d.MaxAccesses,
		Protected:   d.PasswordHash != "",
		Expires:     expires,
	}
}
