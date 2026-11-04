package user

import (
	"net/http"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
)

type APIKey struct {
	ID          string              `json:"id"`
	Created     int64               `json:"created"`
	Expires     int64               `json:"expires"`
	Description string              `json:"description"`
	Scopes      []string            `json:"scopes"`
	LastUsed    auth.ConnectionInfo `json:"last_used"`
}

func setupKeysRoutes(r *gin.RouterGroup) {
	group := r.Group("/keys")
	group.POST("/generate", handleKeysGenerate)
	group.GET("/list", handleKeysList)
	group.POST("/revoke", handleKeysRevoke)
	group.POST("/edit", handleKeysEdit)
}

func handleKeysList(c *gin.Context) {
	var params struct {
		UserID    int32  `json:"user_id" form:"user_id"`
		UserEmail string `json:"user_email" form:"email"`
	}
	if err := c.ShouldBind(&params); err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if (params.UserEmail == "") == (params.UserID <= 0) {
		panic(errInvalidParams)
	}
	userID := params.UserID
	if userID <= 0 {
		if user, err := core.UserByEmail(db.Get(c.Request.Context()), params.UserEmail); err != nil {
			panic(err)
		} else {
			userID = user.ID
		}
	}

	includeExpired := c.Request.URL.Query().Has("show_expired")
	if keys, err := auth.ListAPIKeys(db.Get(c.Request.Context()), userID, includeExpired); err != nil {
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
				LastUsed:    k.LastUsed,
			}
		}
		c.JSON(200, res)
	}
}

func handleKeysGenerate(c *gin.Context) {
	var params struct {
		UserID      int32     `json:"user_id" form:"user_id"`
		UserEmail   string    `json:"user_email" form:"email"`
		Scopes      string    `json:"scopes" form:"scopes"`
		Description string    `json:"description" form:"description"`
		Expires     time.Time `json:"expires" form:"expires"`
	}
	if err := c.ShouldBind(&params); err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if (params.UserEmail == "") == (params.UserID <= 0) {
		panic(errInvalidParams)
	}
	userID := params.UserID
	if userID <= 0 {
		if user, err := core.UserByEmail(db.Get(c.Request.Context()), params.UserEmail); err != nil {
			panic(err)
		} else {
			userID = user.ID
		}
	}

	if params.Description == "" {
		params.Description = "Generated via API"
	}

	a := authenticator.GetAuth(c)
	expires := pgtype.Timestamptz{}
	if !params.Expires.IsZero() {
		expires.Time = params.Expires
		expires.Valid = true
	}
	scopes := a.Scopes()
	if len(params.Scopes) > 0 {
		scopes = strings.Split(params.Scopes, ",")
	}

	if a, err := auth.NewScopedAuth(a, expires, scopes); err != nil {
		panic(err)
	} else if id, key, token, err := auth.GenerateAPIKey(db.Get(c.Request.Context()), userID, params.Description, a.Expires(), a.Scopes()); err != nil {
		panic(err)
	} else {
		c.JSON(200, gin.H{
			"id":    id,
			"key":   key,
			"token": token,
		})
	}
}

func handleKeysRevoke(c *gin.Context) {
	var params struct {
		UserID    int32  `json:"user_id" form:"user_id"`
		UserEmail string `json:"user_email" form:"email"`
		ID        string `json:"id" form:"id" binding:"required"`
		Delete    bool   `json:"delete" form:"delete"`
	}
	if err := c.ShouldBind(&params); err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if (params.UserEmail == "") == (params.UserID <= 0) {
		panic(errInvalidParams)
	}
	userID := params.UserID
	if userID <= 0 {
		if user, err := core.UserByEmail(db.Get(c.Request.Context()), params.UserEmail); err != nil {
			panic(err)
		} else {
			userID = user.ID
		}
	}

	if err := auth.RevokeAPIKey(db.Get(c.Request.Context()), userID, params.ID, params.Delete); err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}

func handleKeysEdit(c *gin.Context) {
	var params struct {
		UserID      int32  `json:"user_id" form:"user_id"`
		UserEmail   string `json:"user_email" form:"email"`
		ID          string `json:"id" form:"id" binding:"required"`
		Description string `json:"description" form:"description" binding:"required"`
	}
	if err := c.ShouldBind(&params); err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if (params.UserEmail == "") == (params.UserID <= 0) {
		panic(errInvalidParams)
	}
	userID := params.UserID
	if userID <= 0 {
		if user, err := core.UserByEmail(db.Get(c.Request.Context()), params.UserEmail); err != nil {
			panic(err)
		} else {
			userID = user.ID
		}
	}

	if err := auth.UpdateAPIKeyDescription(db.Get(c.Request.Context()), userID, params.ID, params.Description); err != nil {
		panic(err)
	}
	c.JSON(200, gin.H{})
}
