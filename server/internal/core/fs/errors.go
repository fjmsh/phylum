package fs

import (
	"net/http"

	"github.com/shroff/phylum/server/internal/core/errors"
)

var (
	ErrInsufficientPermissions        = errors.NewError(http.StatusUnauthorized, "insufficient_permissions", "insufficient permissions")
	ErrResourceNotFound               = errors.NewError(http.StatusNotFound, "resource_not_found", "no such file or directory")
	ErrResourceNotCollection          = errors.NewError(http.StatusMethodNotAllowed, "resource_not_collection", "cannot add member to non-collection resource")
	ErrResourceCollection             = errors.NewError(http.StatusMethodNotAllowed, "resource_collection", "cannot write to collection resource")
	ErrResourceIDConflict             = errors.NewError(http.StatusConflict, "resource_id_conflict", "resource id already exists")
	ErrResourcePathInvalid            = errors.NewError(http.StatusBadRequest, "resource_path_invalid", "invalid path")
	ErrResourceNameInvalid            = errors.NewError(http.StatusBadRequest, "resource_name_invalid", "invalid name")
	ErrResourceNameConflict           = errors.NewError(http.StatusPreconditionFailed, "resource_name_conflict", "resource name already exists")
	ErrResourceMoveTargetSubdirectory = errors.NewError(http.StatusConflict, "move_target_subdirectory", "cannot move resource to its own subdirectory")
	ErrParentNotFound                 = errors.NewError(http.StatusConflict, "parent_not_found", "parent not found")
)
