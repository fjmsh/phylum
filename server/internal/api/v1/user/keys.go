package user

import (
	"fmt"
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
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
	group.POST("/generate", handleKeysGenerate)
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

func handleKeysGenerate(c *gin.Context) {
	var params struct {
		Scopes      []string  `json:"scopes" form:"scopes" binding:"required"`
		Description string    `json:"description" form:"description"`
		Expires     time.Time `json:"expires" form:"expires"`
	}
	if err := c.ShouldBind(&params); err != nil {
		fmt.Println(err)
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}
	if len(params.Scopes) == 0 {
		panic(core.NewError(http.StatusBadRequest, "invalid_scopes", "invalid scopes"))
	}

	if params.Description == "" {
		params.Description = "Generated via API"
	}

	a := authenticator.GetAuth(c)
	if !a.HasScope("keys:generate") {
		panic(core.ErrInsufficientScope)
	}
	expires := pgtype.Timestamptz{}
	if !params.Expires.IsZero() {
		expires.Time = params.Expires
		expires.Valid = true
	}
	if id, key, err := auth.GenerateAPIKey(db.Get(c.Request.Context()), a.UserID(), expires, params.Description, params.Scopes); err != nil {
		panic(err)
	} else {
		c.JSON(200, gin.H{
			"id":  id,
			"key": key,
		})
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
