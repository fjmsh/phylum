package routes

import (
	iofs "io/fs"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
)

var (
	errResourceIDInvalid    = errors.New(http.StatusBadRequest, "resource_id_invalid", "Invalid UUID")
	errResourceIDConflict   = errors.New(http.StatusBadRequest, "resource_id_conflict", "ID already in use")
	errResourceNotFound     = errors.New(http.StatusNotFound, "resource_not_found", "Resource Not Found")
	errResourceNotDirectory = errors.New(http.StatusMethodNotAllowed, "resource_not_directory", "Resource Not Directory")
	errInvalidParams        = errors.New(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")
	errResourceNameConflict = errors.New(http.StatusConflict, "name_conflict", "Resource Name Conflict")
)

type resourceResponse struct {
	ID       uuid.UUID  `json:"id"`
	Parent   *uuid.UUID `json:"parent"`
	Name     string     `json:"name"`
	Dir      bool       `json:"dir"`
	Modified time.Time  `json:"modified"`
	Deleted  *time.Time `json:"deleted,omitempty"`
	Size     int64      `json:"size"`
	Etag     string     `json:"etag"`
}

type resourceDetailResponse struct {
	Metadata             resourceResponse          `json:"metadata"`
	Children             []resourceResponse        `json:"children"`
	InheritedPermissions map[int32]core.Permission `json:"inherited"`
	LocalPermissions     map[int32]core.Permission `json:"local"`
}

type resourceMkdirParams struct {
	Name     string    `json:"name", binding:"required"`
	ParentID uuid.UUID `json:"parent_id", binding:"required"`
}

func SetupResourceRoutes(r *gin.RouterGroup) {
	group := r.Group("/resources")
	group.GET("/ls/:id", handleResourceLsRoute)
	group.GET("/metadata/:id", handleResourceMetadataRoute)
	group.GET("/details/:id", handleResourceDetailsRoute)
	group.POST("/mkdir/:id", handleResourceMkdirRoute)
}

func handleResourceMetadataRoute(c *gin.Context) {
	resourceId, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	resource, err := fs.ResourceByID(resourceId)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}

	c.JSON(200, responseFromResource(resource))
}

func handleResourceLsRoute(c *gin.Context) {
	resourceId, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	resource, err := fs.ResourceByID(resourceId)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}

	if !resource.IsDir() {
		panic(errResourceNotDirectory)
	}
	children, err := fs.ReadDir(resource)
	if err != nil {
		panic(err)
	}
	results := make([]resourceResponse, len(children))
	for i, c := range children {
		results[i] = responseFromResource(c)
	}
	c.JSON(200, results)
}

func handleResourceDetailsRoute(c *gin.Context) {
	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}

	c.JSON(200, detailedResponseFromResource(fs, r))
}

func handleResourceMkdirRoute(c *gin.Context) {
	var params resourceMkdirParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	logrus.Info(params)
	parent, err := fs.ResourceByID(params.ParentID)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}

	res, err := fs.CreateMemberResource(parent, resourceID, params.Name, true)
	if err != nil {
		if err == core.ErrResourceNameConflict {
			err = errResourceNameConflict
		}
		if err == core.ErrResourceIDConflict {
			err = errResourceIDConflict
		}
		panic(err)
	}

	c.JSON(200, detailedResponseFromResource(fs, res))
}

func detailedResponseFromResource(fs core.FileSystem, r core.Resource) resourceDetailResponse {
	response := resourceDetailResponse{}
	response.Metadata = responseFromResource(r)
	if r.IsDir() {
		children, err := fs.ReadDir(r)
		if err != nil {
			panic(err)
		}
		response.Children = make([]resourceResponse, len(children))
		for i, c := range children {
			response.Children[i] = responseFromResource(c)
		}
	}
	if r.Permission() >= core.PermissionReadWriteShare {
		if p, err := fs.GetPermissionsInherited(r); err != nil {
			panic(p)
		} else {
			response.InheritedPermissions = p
		}
		if p, err := fs.GetPermissionsLocal(r); err != nil {
			panic(p)
		} else {
			response.LocalPermissions = p
		}
	}
	return response
}

func responseFromResource(r core.Resource) resourceResponse {
	return resourceResponse{
		ID:       r.ID(),
		Parent:   r.ParentID(),
		Name:     r.Name(),
		Dir:      r.IsDir(),
		Modified: r.ModTime(),
		Deleted:  r.DelTime(),
		Size:     r.Size(),
		Etag:     r.ETag(),
	}
}
