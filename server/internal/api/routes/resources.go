package routes

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/shroff/phylum/server/internal/sql"
)

const errCodeResourceNotFound = "resource_not_found"
const errCodeResourceIdInvalid = "resource_id_invalid"
const errCodeResourceNotCollection = "resource_not_collection"

type resourceResponse struct {
	ID       uuid.UUID  `json:"id"`
	Parent   *uuid.UUID `json:"parent"`
	Name     string     `json:"name"`
	Dir      bool       `json:"dir"`
	Created  time.Time  `json:"created"`
	Modified time.Time  `json:"modified"`
	Deleted  *time.Time `json:"deleted,omitempty"`
	Size     int        `json:"size"`
	Etag     string     `json:"etag"`
}

func SetupResourceRoutes(r *gin.RouterGroup, a *app.App) {
	group := r.Group("/resources")
	group.GET("/:id/ls", createResourceLsRouteHandler(a))
	group.GET("/:id/metadata", createResourceMetadataRouteHandler(a))
}

func createResourceMetadataRouteHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		resourceId, err := uuid.Parse(c.Param("id"))
		if err != nil {
			panic(errors.New(http.StatusBadRequest, errCodeResourceIdInvalid, ""))
		}

		resource, err := a.Db.Queries().ResourceById(context.Background(), resourceId)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				panic(errors.New(http.StatusNotFound, errCodeResourceNotFound, ""))
			}
			panic(err)
		}

		deleted := &resource.Deleted.Time
		if !resource.Deleted.Valid {
			deleted = nil
		}
		response := resourceResponse{
			ID:       resource.ID,
			Parent:   resource.Parent,
			Name:     resource.Name,
			Dir:      resource.Dir,
			Created:  resource.Created.Time,
			Modified: resource.Modified.Time,
			Deleted:  deleted,
			Size:     int(resource.Size.Int32),
			Etag:     resource.Etag.String,
		}
		c.JSON(200, response)
	}
}

func createResourceLsRouteHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		resourceId, err := uuid.Parse(c.Param("id"))
		if err != nil {
			panic(errors.New(http.StatusBadRequest, errCodeResourceIdInvalid, ""))
		}
		resource, err := a.Db.Queries().ResourceById(context.Background(), resourceId)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				panic(errors.New(http.StatusNotFound, errCodeResourceNotFound, ""))
			}
			panic(err)
		}
		if !resource.Dir {
			panic(errors.New(http.StatusBadRequest, errCodeResourceNotCollection, ""))
		}
		children, err := a.Db.Queries().ReadDir(context.Background(), sql.ReadDirParams{IncludeRoot: false, ID: resource.ID, Recursive: false})
		if err != nil {
			panic(err)
		}
		results := make([]resourceResponse, len(children))
		for i, c := range children {
			results[i] = resourceResponse{
				ID:       c.ID,
				Parent:   c.Parent,
				Name:     c.Name,
				Dir:      c.Dir,
				Created:  c.Created.Time,
				Modified: c.Modified.Time,
				Size:     int(c.Size.Int32),
				Etag:     c.Etag.String,
			}
		}
		c.JSON(200, results)
	}
}
