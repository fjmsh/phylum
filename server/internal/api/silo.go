package api

import (
	"context"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/app"
)

type siloResponse struct {
	ID      uuid.UUID `json:"id"`
	Name    string    `json:"name"`
	Owner   string    `json:"owner"`
	Storage string    `json:"storage"`
}

func setupSiloRoutes(r *gin.RouterGroup, a *app.App) {
	group := r.Group("/silos")
	group.GET("/list", createSilosListRouteHandler(a))
}

func createSilosListRouteHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		silos, err := a.ListSilos(context.Background())
		if err != nil {
			c.AbortWithStatusJSON(500, gin.H{
				"ERR_DETAILS": err.Error(),
			})
			return
		}
		results := make([]siloResponse, len(silos))
		for i, s := range silos {
			results[i] = siloResponse{
				ID:      s.ID(),
				Name:    s.Name(),
				Owner:   s.Owner(),
				Storage: s.StorageName(),
			}
		}
		c.JSON(200, results)
	}
}
