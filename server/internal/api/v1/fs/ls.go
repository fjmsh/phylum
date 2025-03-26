package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/core/fs"
)

type AncestorResponse struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	ParentID    uuid.UUID `json:"parent"`
	Permissions string    `json:"permissions"`
}

type InfoResponse struct {
	ID            uuid.UUID `json:"id"`
	Name          string    `json:"name"`
	ParentID      uuid.UUID `json:"parent"`
	Dir           bool      `json:"dir"`
	Created       time.Time `json:"created"`
	Modified      time.Time `json:"modified"`
	ContentLength int64     `json:"c_len"`
	ContentType   string    `json:"c_type"`
	ContentSHA256 string    `json:"c_sha256"`
	Permissions   string    `json:"permissions"`
	Grants        string    `json:"grants"`
}

type FullResponse struct {
	Ancestors []AncestorResponse `json:"ancestors"`
	Info      InfoResponse       `json:"info"`
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

	c.JSON(200, CreateFullResponse(r))
}

func CreateFullResponse(r fs.Resource) FullResponse {
	response := FullResponse{
		Info: CreateResponse(r),
	}
	ancestors, err := r.GetAncestors()
	if err != nil {
		panic(err)
	}
	response.Ancestors = make([]AncestorResponse, len(ancestors))

	for i, a := range ancestors {
		response.Ancestors[i] = AncestorResponse{
			ID:          a.ID,
			Name:        a.Name,
			ParentID:    a.ParentID,
			Permissions: string(a.Permissions),
		}
	}
	if r.Dir() {
		children, err := r.ReadDir(false)
		if err != nil {
			panic(err)
		}
		response.Children = make([]InfoResponse, len(children))
		for i, c := range children {
			response.Children[i] = CreateResponse(c)
		}
	}
	return response
}

func CreateResponse(r fs.Resource) InfoResponse {
	return InfoResponse{
		ID:            r.ID(),
		Name:          r.Name(),
		ParentID:      r.ParentID(),
		Dir:           r.Dir(),
		Created:       r.Created(),
		Modified:      r.Modified(),
		ContentLength: r.ContentLength(),
		ContentType:   r.ContentType(),
		ContentSHA256: r.ContentSHA256(),
		Permissions:   string(r.Permissions()),
		Grants:        string(r.Grants()),
	}
}
