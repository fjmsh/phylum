package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/authenticator"
)

type publinkParams struct {
	Name        string `json:"name" binding:"required"`
	Password    string `json:"password"`
	DurationStr string `json:"duration"`
	ExpiresStr  string `json:"expires"`
	expires     time.Time
	Accesses    int `json:"accesses"`
}

func handlePublinkCreateRequest(c *gin.Context) {
	var params publinkParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.Name == "" {
		panic(errInvalidParams)
	}

	if params.ExpiresStr != "" {
		params.expires, err = time.Parse(time.RFC3339, params.ExpiresStr)
		if err != nil {
			panic(errInvalidParams)
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
		params.expires = time.Now().Add(duration)
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

	if err := r.CreatePublink(params.Name, params.Password, params.expires, params.Accesses); err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{})
}
