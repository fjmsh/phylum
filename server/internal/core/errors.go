package core

import (
	"errors"
	"net/http"
)

type Error struct {
	Status  int    `json:"status"`
	Code    string `json:"code"`
	Message string `json:"msg"`
}

func NewError(httpStatus int, code, msg string) error {
	return &Error{
		Status:  httpStatus,
		Code:    code,
		Message: msg,
	}
}

func NewServerError(msg string) error {
	return &Error{
		Status:  http.StatusInternalServerError,
		Code:    "internal_server_error",
		Message: msg,
	}
}

func (e Error) Error() string {
	return e.Message
}

func Is(err, target error) bool {
	return errors.Is(err, target)
}

var (
	ErrInsufficientPermissions        = NewError(http.StatusUnauthorized, "insufficient_permissions", "Insufficient permissions")
	ErrResourceNotFound               = NewError(http.StatusNotFound, "resource_not_found", "No such file or directory")
	ErrResourceNotCollection          = NewError(http.StatusMethodNotAllowed, "resource_not_collection", "Cannot add a member to a non-collection resource")
	ErrResourceCollection             = NewError(http.StatusMethodNotAllowed, "resource_collection", "Cannot write contents to a collection resource")
	ErrResourceIDConflict             = NewError(http.StatusConflict, "resource_id_conflict", "Another resource with this ID already exists on the server")
	ErrResourcePathInvalid            = NewError(http.StatusBadRequest, "resource_path_invalid", "Resource path is invalid")
	ErrResourceNameInvalid            = NewError(http.StatusBadRequest, "resource_name_invalid", "Resource name is invalid")
	ErrResourceNameConflict           = NewError(http.StatusPreconditionFailed, "resource_name_conflict", "Another resource with this name already exists")
	ErrResourceMoveTargetSubdirectory = NewError(http.StatusConflict, "move_target_subdirectory", "Cannot move a resource to its own subdirectory")
	ErrResourceCopyTargetSelf         = NewError(http.StatusConflict, "copy_target_self", "Cannot overwrite a resource with itself")
	ErrResourceDeleted                = NewError(http.StatusPreconditionFailed, "resource_deleted", "Resource is deleted")
	ErrParentNotFound                 = NewError(http.StatusConflict, "parent_not_found", "Parent not found")
	ErrParentDeleted                  = NewError(http.StatusConflict, "parent_deleted", "Parent deleted")
	ErrPublinkNameConflict            = NewError(http.StatusPreconditionFailed, "publink_name_conflict", "Another public share with this name already exists")
	ErrVersionNotFound                = NewError(http.StatusNotFound, "version_not_found", "Version Not Foud")
)
