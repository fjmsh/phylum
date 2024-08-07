package routes

import (
	iofs "io/fs"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/errors"
)

const errCodeResourceNotFound = "resource_not_found"
const errCodeResourceIdInvalid = "resource_id_invalid"
const errCodeResourceNotCollection = "resource_not_collection"

type resourceResponse struct {
	ID       uuid.UUID  `json:"id"`
	Parent   *uuid.UUID `json:"parent"`
	Name     string     `json:"name"`
	Dir      bool       `json:"dir"`
	Modified time.Time  `json:"modified"`
	Deleted  *time.Time `json:"deleted,omitempty"`
	Size     int64      `json:"size"`
	Etag     string     `json:"etag"`
}

func SetupResourceRoutes(r *gin.RouterGroup) {
	group := r.Group("/resources")
	group.GET("/ls/:id", handleResourceLsRoute)
	group.GET("/metadata/:id", handleResourceMetadataRoute)
}

func handleResourceMetadataRoute(c *gin.Context) {
	resourceId, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errors.New(http.StatusBadRequest, errCodeResourceIdInvalid, ""))
	}

	fs := auth.GetFileSystem(c)
	resource, err := fs.ResourceByID(resourceId)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errors.New(http.StatusNotFound, errCodeResourceNotFound, "")
		}
		panic(err)
	}

	response := resourceResponse{
		ID:       resource.ID(),
		Parent:   resource.ParentID(),
		Name:     resource.Name(),
		Dir:      resource.IsDir(),
		Modified: resource.ModTime(),
		Deleted:  resource.DelTime(),
		Size:     resource.Size(),
		Etag:     resource.ETag(),
	}
	c.JSON(200, response)
}

func handleResourceLsRoute(c *gin.Context) {
	resourceId, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errors.New(http.StatusBadRequest, errCodeResourceIdInvalid, ""))
	}

	fs := auth.GetFileSystem(c)
	resource, err := fs.ResourceByID(resourceId)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errors.New(http.StatusNotFound, errCodeResourceNotFound, "")
		}
		panic(err)
	}

	if !resource.IsDir() {
		panic(errors.New(http.StatusBadRequest, errCodeResourceNotCollection, ""))
	}
	children, err := fs.ReadDir(resource)
	if err != nil {
		panic(err)
	}
	results := make([]resourceResponse, len(children))
	for i, c := range children {
		results[i] = resourceResponse{
			ID:       c.ID(),
			Parent:   c.ParentID(),
			Name:     c.Name(),
			Dir:      c.IsDir(),
			Modified: c.ModTime(),
			Size:     c.Size(),
			Etag:     c.ETag(),
		}
	}
	c.JSON(200, results)
}
