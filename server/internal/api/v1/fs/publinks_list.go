package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type Publink struct {
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

func publinkFromFS(p fs.Publink) Publink {
	var deleted *time.Time
	if p.Deleted.Valid {
		deleted = &p.Deleted.Time
	}
	var expires *time.Time
	if p.Expires.Valid {
		expires = &p.Expires.Time
	}
	return Publink{
		ID:          p.ID,
		Name:        p.Name,
		Created:     p.Created,
		Deleted:     deleted,
		CreatedBy:   p.CreatedBy,
		Root:        p.Root,
		Accessed:    p.Accessed,
		MaxAccesses: p.MaxAccesses,
		Protected:   p.PasswordHash != "",
		Expires:     expires,
	}
}

func handlePublinkListRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}

	res, err := r.ListPublinks()
	if err != nil {
		panic(err)
	}
	links := make([]Publink, len(res))
	for i, l := range res {
		links[i] = publinkFromFS(l)
	}

	c.JSON(200, gin.H{
		"publinks": links,
	})
}
