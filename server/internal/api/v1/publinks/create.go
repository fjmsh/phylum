package publinks

import (
	"time"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
)

type createParams struct {
	ID           string `json:"id" form:"id" binding:"required"`
	ResourcePath string `json:"resource_path" form:"resource_path" binding:"required"`
	Password     string `json:"password" form:"password"`
	DurationStr  string `json:"duration" form:"duration"`
	ExpiresStr   string `json:"expires" form:"expires"`
	AccessLimit  int    `json:"access_limit" form:"access_limit"`
}

func handleCreateRequest(c *gin.Context) {
	var params createParams
	err := c.ShouldBind(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}

	var expires pgtype.Timestamp
	if params.ExpiresStr != "" {
		exp, err := time.Parse(time.RFC3339, params.ExpiresStr)
		if err != nil {
			panic(errInvalidParams)
		}
		expires = pgtype.Timestamp{
			Time:  exp,
			Valid: true,
		}
	}
	if params.DurationStr != "" {
		if params.ExpiresStr != "" {
			panic(errInvalidParams)
		}
		duration, err := time.ParseDuration(params.DurationStr)
		if err != nil || duration.Milliseconds() < 0 {
			panic(errInvalidParams)
		}
		expires = pgtype.Timestamp{
			Time:  time.Now().Add(duration),
			Valid: true,
		}
	}

	auth := authenticator.GetAuth(c)
	fs := auth.GetFileSystem(db.Get(c.Request.Context()))
	r, err := fs.ResourceByPath(params.ResourcePath)
	if err != nil {
		panic(err)
	}

	if err := fs.CreatePublink(r, params.ID, params.Password, expires, params.AccessLimit); err != nil {
		panic(err)
	}
	var expiresS int64
	if expires.Valid {
		expiresS = expires.Time.Unix()
	}
	response := responses.Publink{
		ID:          params.ID,
		Created:     time.Now().Unix(),
		Expires:     expiresS,
		Root:        r.ID(),
		AccessLimit: int32(params.AccessLimit),
		Protected:   params.Password != "",
	}

	c.JSON(200, response)
}
