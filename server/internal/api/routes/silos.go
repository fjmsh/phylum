package routes

import (
	"context"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/app"
)

type siloResponse struct {
	ID      uuid.UUID `json:"id"`
	Name    string    `json:"name"`
	Owner   int32     `json:"owner"`
	Storage string    `json:"storage"`
}

func SetupSiloRoutes(r *gin.RouterGroup, a *app.App) {
	group := r.Group("/silos")
	group.GET("/list", createSiloListRouteHandler(a))
}

func createSiloListRouteHandler(a *app.App) func(c *gin.Context) {
	return func(c *gin.Context) {
		silos, err := a.SilosForUser(context.Background(), auth.GetUserID(c))
		if err != nil {
			panic(err)
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
