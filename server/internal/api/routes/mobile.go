package routes

import (
	iofs "io/fs"

	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/errors"
)

type mobileHomeResponse struct {
	User userResponse           `json:"user"`
	Home resourceDetailResponse `json:"home"`
}

func SetupMobileRoutes(r *gin.RouterGroup) {
	group := r.Group("/mobile")
	group.GET("/home", handleMobileHomeRoute)
}

func handleMobileHomeRoute(c *gin.Context) {
	user := auth.GetUser(c)
	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(user.Home)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}

	c.JSON(200, mobileHomeResponse{
		User: responseFromUser(user),
		Home: detailedResponseFromResource(fs, r),
	})
}
