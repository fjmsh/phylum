package routes

import (
	"io"
	iofs "io/fs"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/auth"
	"github.com/shroff/phylum/server/internal/api/errors"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/net/serve"
)

var (
	errInsufficientPermissions = errors.New(http.StatusBadRequest, "insufficient_permissions", "Insufficient Permissions")
	errResourceIDInvalid       = errors.New(http.StatusBadRequest, "resource_id_invalid", "Invalid UUID")
	errResourceIDConflict      = errors.New(http.StatusBadRequest, "resource_id_conflict", "ID already in use")
	errResourceNotFound        = errors.New(http.StatusNotFound, "resource_not_found", "Resource Not Found")
	errResourceNotDirectory    = errors.New(http.StatusMethodNotAllowed, "resource_not_directory", "Resource Not Directory")
	errInvalidParams           = errors.New(http.StatusBadRequest, "invalid_parameters", "Invalid Request Parameters")
	errResourceNameConflict    = errors.New(http.StatusConflict, "name_conflict", "Resource Name Conflict")
)

type resourceResponse struct {
	ID          uuid.UUID  `json:"id"`
	Parent      *uuid.UUID `json:"parent"`
	Name        string     `json:"name"`
	Dir         bool       `json:"dir"`
	Modified    time.Time  `json:"modified"`
	Deleted     *time.Time `json:"deleted,omitempty"`
	ContentType string     `json:"ctype,omitEmpty"`
	Size        int64      `json:"size"`
	Etag        string     `json:"etag"`
}

type resourceDetailResponse struct {
	Metadata             resourceResponse          `json:"metadata"`
	Children             []resourceResponse        `json:"children,omitempty"`
	InheritedPermissions map[int32]core.Permission `json:"inherited,omitempty"`
	LocalPermissions     map[int32]core.Permission `json:"local,omitempty"`
}

type resourceMkdirParams struct {
	Name     string    `json:"name" binding:"required"`
	ParentID uuid.UUID `json:"parent_id" binding:"required"`
}

type resourceRenameParams struct {
	Name string `json:"name" binding:"required"`
}

type resourceMoveParams struct {
	ParentID uuid.UUID `json:"parent_id" binding:"required"`
}

func SetupResourceRoutes(r *gin.RouterGroup) {
	group := r.Group("/resources")
	group.GET("/ls/:id", handleResourceLsRoute)
	group.GET("/metadata/:id", handleResourceMetadataRoute)
	group.GET("/details/:id", handleResourceDetailsRoute)
	group.GET("/contents/:id", handleResourceContentsRoute)
	group.POST("/mkdir/:id", handleResourceMkdirRoute)
	group.POST("/rename/:id", handleResourceRenameRoute)
	group.POST("/move/:id", handleResourceMoveRoute)
	group.PUT("/upload/:id", handleResourceUploadRoute)
	group.DELETE("/delete/:id", handleResourceDeleteRoute)
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

	children, err := fs.ReadDir(resource)
	if err != nil {
		if errors.Is(err, core.ErrResourceNotCollection) {
			panic(errResourceNotDirectory)
		}
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

func handleResourceContentsRoute(c *gin.Context) {
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
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}

	res, err := fs.CreateMemberResource(parent, resourceID, params.Name, true)
	if err != nil {
		if errors.Is(err, core.ErrInsufficientPermissions) {
			panic(errInsufficientPermissions)
		}
		if errors.Is(err, core.ErrResourceNotCollection) {
			panic(errResourceNotDirectory)
		}
		if errors.Is(err, core.ErrResourceNameConflict) {
			panic(errResourceNameConflict)
		}
		if errors.Is(err, core.ErrResourceIDConflict) {
			panic(errResourceIDConflict)
		}
		panic(err)
	}

	c.JSON(200, responseFromResource(res))
}

func handleResourceRenameRoute(c *gin.Context) {
	var params resourceRenameParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.Name == "" {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			panic(errResourceNotFound)
		}
		panic(err)
	}
	if r, err := fs.UpdateName(r, params.Name); err != nil {
		if errors.Is(err, core.ErrInsufficientPermissions) {
			panic(errInsufficientPermissions)
		}
		panic(err)
	} else {
		c.JSON(200, responseFromResource(r))
	}
}

func handleResourceMoveRoute(c *gin.Context) {
	var params resourceMoveParams
	err := c.ShouldBindJSON(&params)
	if err != nil || params.ParentID == uuid.Nil {
		panic(errInvalidParams)
	}

	resourceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(resourceID)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			panic(errResourceNotFound)
		}
		panic(err)
	}

	if r, err := fs.UpdateParent(r, params.ParentID); err != nil {
		if errors.Is(err, core.ErrInsufficientPermissions) {
			panic(errInsufficientPermissions)
		}
		panic(err)
	} else {
		c.JSON(200, responseFromResource(r))
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
			if errors.Is(err, iofs.ErrNotExist) {
				return errResourceNotFound
			}
			return err
		}

		res, err := fs.CreateMemberResource(parent, resourceID, name, false)
		if err != nil {
			if errors.Is(err, core.ErrInsufficientPermissions) {
				panic(errInsufficientPermissions)
			}
			if errors.Is(err, core.ErrResourceNotCollection) {
				panic(errResourceNotDirectory)
			}
			if errors.Is(err, core.ErrResourceNameConflict) {
				panic(errResourceNameConflict)
			}
			if errors.Is(err, core.ErrResourceIDConflict) {
				panic(errResourceIDConflict)
			}
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
	res, err := f.ResourceByID(resourceID)
	if err != nil {
		panic(err)
	}
	c.JSON(200, responseFromResource(res))
}

func handleResourceDeleteRoute(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		panic(errResourceIDInvalid)
	}

	fs := auth.GetFileSystem(c)
	r, err := fs.ResourceByID(id)
	if err != nil {
		if errors.Is(err, iofs.ErrNotExist) {
			err = errResourceNotFound
		}
		panic(err)
	}
	ids, err := fs.DeleteRecursive(r, false)
	if err != nil {
		panic(err)
	}

	c.JSON(200, gin.H{"ids": ids})
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
		ID:          r.ID(),
		Parent:      r.ParentID(),
		Name:        r.Name(),
		Dir:         r.IsDir(),
		Modified:    r.ModTime(),
		Deleted:     r.DelTime(),
		Size:        r.Size(),
		Etag:        r.ETag(),
		ContentType: r.ContentType(),
	}
}
