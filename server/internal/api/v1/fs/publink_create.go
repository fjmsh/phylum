package fs

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
)

type publinkParams struct {
	Name        string `json:"name" binding:"required"`
	Password    string `json:"password"`
	DurationStr string `json:"duration"`
	duration    time.Duration
	Accesses    int `json:"accesses"`
}

func handlePublinkCreateRequest(c *gin.Context) {
	var params publinkParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.Name == "" {
		panic(errInvalidParams)
	}
	params.duration, err = time.ParseDuration(params.DurationStr)
	if err != nil || params.duration.Milliseconds() < 0 {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}

	if err := r.CreatePublink(params.Name, params.Password, params.duration, params.Accesses); err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{})
}
