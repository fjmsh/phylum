package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type ancestor struct {
	ID          uuid.UUID  `json:"id"`
	Name        string     `json:"name"`
	ParentID    *uuid.UUID `json:"parent"`
	Permissions string     `json:"permissions"`
}

type info struct {
	ID            uuid.UUID  `json:"id"`
	Name          string     `json:"name"`
	ParentID      *uuid.UUID `json:"parent"`
	Dir           bool       `json:"dir"`
	Created       time.Time  `json:"created"`
	Modified      time.Time  `json:"modified"`
	ContentSize   int64      `json:"c_size"`
	ContentType   string     `json:"c_type"`
	ContentSHA256 string     `json:"c_sha256"`
	Permissions   string     `json:"permissions"`
	Publinks      int        `json:"publinks"`
}

type ResourceResponse struct {
	Ancestors []ancestor `json:"ancestors"`
	Info      info       `json:"info"`
	Children  []info     `json:"children"`
}

func handleLsRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}

	c.JSON(200, LsResponseFromResource(r))
}

func LsResponseFromResource(r fs.Resource) ResourceResponse {
	response := ResourceResponse{
		Info: createInfo(r.Info),
	}
	response.Ancestors = make([]ancestor, len(r.Ancestors))

	for i, a := range r.Ancestors {
		response.Ancestors[i] = ancestor{
			ID:          a.ID(),
			Name:        a.Name(),
			ParentID:    a.ParentID(),
			Permissions: string(a.Permissions()),
		}
	}
	if r.Dir() {
		children, err := r.ReadDir(false)
		if err != nil {
			panic(err)
		}
		response.Children = make([]info, len(children))
		for i, c := range children {
			response.Children[i] = createInfo(c.(fs.ResourceInfo))
		}
	}
	return response
}

func createInfo(r fs.ResourceInfo) info {
	return info{
		ID:            r.ID(),
		Name:          r.Name(),
		ParentID:      r.ParentID(),
		Dir:           r.Dir(),
		Created:       r.Created(),
		Modified:      r.Modified(),
		ContentSize:   r.ContentSize(),
		ContentType:   r.ContentType(),
		ContentSHA256: r.ContentSHA256(),
		Permissions:   string(r.Permissions()),
		Publinks:      r.Publinks(),
	}
}
