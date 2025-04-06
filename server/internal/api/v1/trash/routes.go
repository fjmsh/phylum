package trash

import (
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
)

const trashListLength = 100

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/trash")

	group.GET("/list", handleListRequest)
}

type trashListResponse struct {
	Resources []responses.Resource `json:"resources"`
	Cursor    string               `json:"c"`
}

func handleListRequest(c *gin.Context) {
	cursor := c.Request.URL.Query().Get("c")

	fs := auth.GetFileSystem(c)
	res, cursor, err := fs.TrashList(cursor, trashListLength)
	if err != nil {
		panic(err)
	}

	var r trashListResponse
	r.Cursor = cursor
	r.Resources = make([]responses.Resource, len(res))
	for i, c := range res {
		r.Resources[i] = responses.ResourceFromFS(c)
	}

	c.JSON(200, r)
}
