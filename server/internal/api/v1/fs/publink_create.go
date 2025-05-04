package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/api/authenticator"
)

type publinkParams struct {
	ID          string `json:"id" binding:"required"`
	Password    string `json:"password"`
	DurationStr string `json:"duration"`
	ExpiresStr  string `json:"expires"`
	AccessLimit int    `json:"access_limit"`
}

func handlePublinksCreateRequest(c *gin.Context) {
	var params publinkParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.ID == "" {
		panic(errInvalidParams)
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

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := authenticator.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}

	if err := r.CreatePublink(params.ID, params.Password, expires, params.AccessLimit); err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{})
}
