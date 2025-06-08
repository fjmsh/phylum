package fs

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
)

var errSearchQueryEmpty = core.NewError(http.StatusBadRequest, "search_query_empty", "Empty Search Query")

func handleSearchRequest(c *gin.Context) {
	query := c.Request.URL.Query().Get("q")
	if query == "" {
		panic(errSearchQueryEmpty)
	}

	fs := authenticator.GetFileSystem(c)
	res, err := fs.Search(query, false)
	if err != nil {
		panic(err)
	}

	r := make([]responses.Resource, len(res))
	for i, c := range res {
		r[i] = responses.ResourceFromFS(c)
	}

	c.JSON(200, r)
}
