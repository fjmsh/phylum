package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type Publink struct {
	ID          string    `json:"id"`
	Created     time.Time `json:"created"`
	Root        uuid.UUID `json:"root"`
	Accessed    int32     `json:"accessed"`
	AccessLimit int32     `json:"access_limit"`
	Protected   bool      `json:"protected"`
	Expires     int64     `json:"expires"`
}

func publinkFromFS(p fs.Publink) Publink {
	return Publink{
		ID:          p.ID,
		Created:     p.Created,
		Root:        p.Root,
		Accessed:    p.Accessed,
		AccessLimit: p.AccessLimit,
		Protected:   p.PasswordHash != "",
		Expires:     p.Expires,
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
