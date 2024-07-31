package api

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/sirupsen/logrus"
)

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

func setupResourceRoutes(r *gin.RouterGroup, a *app.App) {
	group := r.Group("/resources")
	group.GET("/:id/ls", createResourceLsRouteHandler(a))
}

func createResourceLsRouteHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		resourceId, err := uuid.Parse(c.Param("id"))
		if err != nil {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"ERR_CODE": "resource_not_found",
			})
			return
		}
		resource, err := a.Db.Queries().ResourceById(context.Background(), resourceId)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				c.JSON(http.StatusNotFound, gin.H{
					"ERR_CODE": "resource_not_found",
				})
			} else {
				logrus.Warn(err)
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"ERR_CODE":    "unknown_error",
					"ERR_DETAILS": err.Error(),
				})
			}
			return
		}
		if !resource.Dir {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"ERR_CODE": "resource_not_collection",
			})
			return
		}
		children, err := a.Db.Queries().ReadDir(context.Background(), sql.ReadDirParams{IncludeRoot: false, ID: resource.ID, Recursive: false})
		if err != nil {
			logrus.Warn(err)
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
				"ERR_CODE":    "unknown_error",
				"ERR_DETAILS": err.Error(),
			})
			return
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
