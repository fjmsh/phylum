package user

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

type APIKey struct {
	ID          string   `json:"id"`
	Created     int64    `json:"created"`
	Expires     int64    `json:"expires"`
	Description string   `json:"description"`
	Scopes      []string `json:"scopes"`
}

func setupKeysRoutes(r *gin.RouterGroup) {
	group := r.Group("/keys")
	group.GET("/list", handleKeysList)
	group.POST("/revoke", handleKeysRevoke)
}

func handleKeysList(c *gin.Context) {
	includeExpired := c.Request.URL.Query().Has("show_expired")
	a := authenticator.GetAuth(c)
	if !a.HasScope("keys:list") {
		panic(core.ErrInsufficientScope)
	}
	if keys, err := auth.ListAPIKeys(db.Get(c.Request.Context()), a.UserID(), includeExpired); err != nil {
		panic(err)
	} else {
		res := make([]APIKey, len(keys))
		for i, k := range keys {
			var expires int64 = 0
			if k.Expires.Valid {
				expires = k.Expires.Time.Unix()
			}
			res[i] = APIKey{
				ID:          k.ID,
				Created:     k.Created.Unix(),
				Expires:     expires,
				Description: k.Description,
				Scopes:      k.Scopes,
			}
		}
		c.JSON(200, res)
	}
}

func handleKeysRevoke(c *gin.Context) {
	var params struct {
		ID     string `json:"id" form:"id" binding:"required"`
		Delete bool   `json:"delete" form:"delete"`
	}
	if err := c.ShouldBind(&params); err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	a := authenticator.GetAuth(c)
	if !a.HasScope("keys:revoke") {
		panic(core.ErrInsufficientScope)
	}
	if err := auth.RevokeAPIKey(db.Get(c.Request.Context()), a.UserID(), params.ID, params.Delete); err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}
