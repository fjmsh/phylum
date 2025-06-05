package publinks

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/api/authenticator"
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

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByPathWithRoot(params.ResourcePath)
	if err != nil {
		panic(err)
	}

	if err := fs.CreatePublink(r, params.ID, params.Password, expires, params.AccessLimit); err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{})
}
