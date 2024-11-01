package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type AncestorResponse struct {
	ID          uuid.UUID  `json:"id"`
	Name        string     `json:"name"`
	ParentID    *uuid.UUID `json:"parent"`
	Permissions string     `json:"permissions"`
}

type InfoResponse struct {
	ID            uuid.UUID  `json:"id"`
	Name          string     `json:"name"`
	ParentID      *uuid.UUID `json:"parent"`
	Dir           bool       `json:"dir"`
	Created       time.Time  `json:"created"`
	Modified      time.Time  `json:"modified"`
	Deleted       *time.Time `json:"deleted"`
	ContentSize   int64      `json:"c_size"`
	ContentType   string     `json:"c_type"`
	ContentSHA256 string     `json:"c_sha256"`
	Permissions   string     `json:"permissions"`
	Publinks      int        `json:"publinks"`
}

type ResourceResponse struct {
	Ancestors []AncestorResponse `json:"ancestors"`
	Resource  InfoResponse       `json:"resource"`
	Children  []InfoResponse     `json:"children"`
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
		Resource: infoResponse(r.Resource),
	}
	response.Ancestors = make([]AncestorResponse, len(r.Ancestry))

	for i, c := range r.Ancestry {
		response.Ancestors[i] = ancestorResponse(c)
	}
	if r.Dir() {
		children, err := r.ReadDir(false)
		if err != nil {
			panic(err)
		}
		response.Children = make([]InfoResponse, len(children))
		for i, c := range children {
			response.Children[i] = infoResponse(c.(fs.ResourceInfo))
		}
	}
	return response
}

func ancestorResponse(r fs.ResourceInfo) AncestorResponse {
	return AncestorResponse{
		ID:          r.ID(),
		Name:        r.Name(),
		ParentID:    r.ParentID(),
		Permissions: string(r.Permissions()),
	}
}

func infoResponse(r fs.ResourceInfo) InfoResponse {
	return InfoResponse{
		ID:            r.ID(),
		Name:          r.Name(),
		ParentID:      r.ParentID(),
		Dir:           r.Dir(),
		Created:       r.Created(),
		Modified:      r.Modified(),
		Deleted:       r.Deleted(),
		ContentSize:   r.ContentSize(),
		ContentType:   r.ContentType(),
		ContentSHA256: r.ContentSHA256(),
		Permissions:   string(r.Permissions()),
		Publinks:      r.Publinks(),
	}
}
