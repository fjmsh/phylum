package trash

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/v1/responses"
	"github.com/shroff/phylum/server/internal/core/errors"
)

const trashListLength = 100

var errResourceIDInvalid = errors.NewError(http.StatusBadRequest, "resource_id_invalid", "Invalid UUID")

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/trash")

	group.GET("/list", handleListRequest)
	group.POST("/empty", handleEmptyRequest)
	group.POST("/restore/:id", handleRestoreRequest)
}

type trashListResponse struct {
	Resources []responses.Resource `json:"resources"`
	Clear     bool                 `json:"clear"`
	Cursor    string               `json:"cursor"`
}

func handleListRequest(c *gin.Context) {
	cursor := c.Request.URL.Query().Get("cursor")

	fs := auth.GetFileSystem(c)
	res, cursor, err := fs.TrashList(cursor, trashListLength)
	if err != nil {
		panic(err)
	}

	var r trashListResponse
	r.Cursor = cursor
	r.Clear = c.Request.URL.Query().Get("cursor") == ""
	r.Resources = make([]responses.Resource, len(res))
	for i, c := range res {
		r.Resources[i] = responses.ResourceFromFS(c)
	}

	c.JSON(200, r)
}

func handleEmptyRequest(c *gin.Context) {
	fs := auth.GetFileSystem(c)
	_, err := fs.TrashEmpty()
	if err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}

func handleRestoreRequest(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}
	target := c.Request.URL.Query().Get("target")
	name := c.Request.URL.Query().Get("name")
	autoRename := c.Request.URL.Query().Has("auto_rename")

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}
	r, _, _, err = r.RestoreDeleted(target, name, autoRename)
	if err != nil {
		panic(err)
	}

	c.JSON(200, responses.ResourceFromFS(r))
}
