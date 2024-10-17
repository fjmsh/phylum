package core

import (
	"net/http"

	"github.com/shroff/phylum/server/internal/api/errors"
)

var ErrInsufficientPermissions = errors.New(http.StatusUnauthorized, "insufficient_permissions", "")

var ErrUserNotFound = errors.New(http.StatusNotFound, "user_not_found", "")

var (
	ErrResourceNotFound               = errors.New(http.StatusNotFound, "resource_not_found", "no such file or directory")
	ErrResourceNotCollection          = errors.New(http.StatusMethodNotAllowed, "resource_not_collection", "cannot add member to non-collection resource")
	ErrResourceCollection             = errors.New(http.StatusMethodNotAllowed, "resource_collection", "cannot write to collection resource")
	ErrResourceIDConflict             = errors.New(http.StatusConflict, "resource_id_conflict", "")
	ErrResourceNameInvalid            = errors.New(http.StatusBadRequest, "resource_name_invalid", "")
	ErrResourceNameConflict           = errors.New(http.StatusPreconditionFailed, "resource_name_conflict", "")
	ErrResourceMoveTargetSubdirectory = errors.New(http.StatusConflict, "move target subdirectory", "")
	ErrParentNotFound                 = errors.New(http.StatusConflict, "parent_not_found", "")
)
