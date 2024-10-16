package fs

import (
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/net/serve"
)

var (
	errResourceIDInvalid = errors.New(http.StatusBadRequest, "resource_id_invalid", "Invalid UUID")
	errInvalidParams     = errors.New(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")
)

type resourceMkdirParams struct {
	Name     string    `json:"name" binding:"required"`
	ParentID uuid.UUID `json:"parent_id" binding:"required"`
}

type resourceMoveParams struct {
	ParentID  uuid.UUID `json:"parent_id"`
	Name      string    `json:"name"`
	Overwrite bool      `json:"overwrite"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/resources")
	group.GET("/du/:id", handleResourceDiskUsageRoute)
	group.GET("/ls/:id", handleResourceLsRoute)
	group.GET("/contents/:id", handleResourceContentsRoute)
	group.POST("/mkdir/:id", handleResourceMkdirRoute)
	group.POST("/move/:id", handleResourceMoveRoute)
	group.PUT("/upload/:id", handleResourceUploadRoute)
	group.DELETE("/delete/:id", handleResourceDeleteRoute)
}

func handleResourceDiskUsageRoute(c *gin.Context) {
	resourceId, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	resource, err := fs.ResourceByID(resourceId)
	if err != nil {
		panic(err)
	}

	info, err := fs.DiskUsage(resource)
	if err != nil {
		panic(err)
	}
	c.JSON(200, DiskUsageResponse{
		TotalSize: info.TotalSize,
		Files:     info.Files,
		Dirs:      info.Dirs,
	})
}

func handleResourceContentsRoute(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}
	serve.ServeResource(c.Writer, c.Request, fs, r)
}

func handleResourceMkdirRoute(c *gin.Context) {
	var params resourceMkdirParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.Name == "" {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	parent, err := fs.ResourceByID(params.ParentID)
	if err != nil {
		panic(err)
	}

	r, err := fs.CreateMemberResource(parent, resourceID, params.Name, true)
	if err != nil {
		panic(err)
	}

	c.JSON(200, r)
}

func handleResourceMoveRoute(c *gin.Context) {
	var params resourceMoveParams
	err := c.ShouldBindJSON(&params)
	if err != nil || (params.ParentID == uuid.Nil && params.Name == "") {
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

	if r, err := fs.Move(r, params.ParentID, params.Name, params.Overwrite); err != nil {
		panic(err)
	} else {
		c.JSON(200, r)
	}
}

func handleResourceUploadRoute(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	name := c.Request.FormValue("name")
	parentID, err := uuid.Parse(c.Request.FormValue("parent_id"))
	if err != nil || name == "" {
		panic(errInvalidParams)
	}
	// TODO: Calculate and verify sha sum
	// c.Request.FormValue("sha256sum")

	f := auth.GetFileSystem(c)
	err = f.RunInTx(func(fs core.FileSystem) error {
		parent, err := fs.ResourceByID(parentID)
		if err != nil {
			return err
		}

		res, err := fs.CreateMemberResource(parent, resourceID, name, false)
		if err != nil {
			return err
		}

		file, err := c.FormFile("contents")
		if err != nil {
			if err == http.ErrMissingFile {
				return errInvalidParams
			}
			return err
		}

		src, err := file.Open()
		if err != nil {
			return err
		}
		defer src.Close()

		out, err := fs.OpenWrite(res)
		if err != nil {
			return err
		}
		defer out.Close()

		_, err = io.Copy(out, src)
		return err
	})
	if err != nil {
		panic(err)
	}

	// TODO: Avoid reading from db again if we can update size and etag
	r, err := f.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}
	c.JSON(200, r)
}

func handleResourceDeleteRoute(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(id)
	if err != nil {
		panic(err)
	}
	ids, err := fs.DeleteRecursive(r, false)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{"ids": ids})
}
