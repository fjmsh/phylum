package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type Publink struct {
	ID          string     `json:"id"`
	Created     time.Time  `json:"created"`
	Deleted     *time.Time `json:"deleted"`
	CreatedBy   string     `json:"creator"`
	Root        uuid.UUID  `json:"root"`
	Accessed    int32      `json:"accessed"`
	AccessLimit int32      `json:"access_limit"`
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
		Created:     p.Created,
		Deleted:     deleted,
		CreatedBy:   p.CreatedBy,
		Root:        p.Root,
		Accessed:    p.Accessed,
		AccessLimit: p.MaxAccesses,
		Protected:   p.PasswordHash != "",
		Expires:     expires,
	}
}

func handlePublinksListRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := authenticator.GetFileSystem(c)
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
