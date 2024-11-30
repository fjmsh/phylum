package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type ResourceAncestorResponse struct {
	ID          uuid.UUID  `json:"id"`
	Name        string     `json:"name"`
	ParentID    *uuid.UUID `json:"parent"`
	Permissions string     `json:"permissions"`
}

type ResourceInfoResponse struct {
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
	Publinks      string     `json:"publinks"`
}

type ResourceResponse struct {
	Ancestors []ResourceAncestorResponse `json:"ancestors"`
	Info      ResourceInfoResponse       `json:"info"`
	Children  []ResourceInfoResponse     `json:"children"`
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

	c.JSON(200, ResponseFromResource(r))
}

func ResponseFromResource(r fs.Resource) ResourceResponse {
	response := ResourceResponse{
		Info: ResponseFromResourceInfo(r.Info),
	}
	response.Ancestors = make([]ResourceAncestorResponse, len(r.Ancestors))

	for i, a := range r.Ancestors {
		response.Ancestors[i] = ResourceAncestorResponse{
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
		response.Children = make([]ResourceInfoResponse, len(children))
		for i, c := range children {
			response.Children[i] = ResponseFromResourceInfo(c.(fs.ResourceInfo))
		}
	}
	return response
}

func ResponseFromResourceInfo(r fs.ResourceInfo) ResourceInfoResponse {
	return ResourceInfoResponse{
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
		Publinks:      string(r.Publinks()),
	}
}
