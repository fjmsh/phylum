package fs

import (
	"net/http"

	"github.com/shroff/phylum/server/internal/core/errors"
)

var (
	ErrInsufficientPermissions        = errors.NewError(http.StatusUnauthorized, "insufficient_permissions", "Insufficient permissions")
	ErrResourceNotFound               = errors.NewError(http.StatusNotFound, "resource_not_found", "No such file or directory")
	ErrResourceNotCollection          = errors.NewError(http.StatusMethodNotAllowed, "resource_not_collection", "Cannot add a member to a non-collection resource")
	ErrResourceCollection             = errors.NewError(http.StatusMethodNotAllowed, "resource_collection", "Cannot write contents to a collection resource")
	ErrResourceIDConflict             = errors.NewError(http.StatusConflict, "resource_id_conflict", "Another resource with this ID already exists on the server")
	ErrResourcePathInvalid            = errors.NewError(http.StatusBadRequest, "resource_path_invalid", "Resource path is invalid")
	ErrResourceNameInvalid            = errors.NewError(http.StatusBadRequest, "resource_name_invalid", "Resource name is invalid")
	ErrResourceNameConflict           = errors.NewError(http.StatusPreconditionFailed, "resource_name_conflict", "Another resource with this name already exists")
	ErrResourceMoveTargetSubdirectory = errors.NewError(http.StatusConflict, "move_target_subdirectory", "Cannot move a resource to its own subdirectory")
	ErrResourceCopyTargetSelf         = errors.NewError(http.StatusConflict, "copy_target_self", "Cannot overwrite a resource with itself")
	ErrParentNotFound                 = errors.NewError(http.StatusConflict, "parent_not_found", "Parent not found")
	ErrParentDeleted                  = errors.NewError(http.StatusConflict, "parent_deleted", "Parent deleted")
	ErrPublinkNameConflict            = errors.NewError(http.StatusPreconditionFailed, "publink_name_conflict", "Another public share with this name already exists")
)
