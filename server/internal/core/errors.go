package core

import "net/http"

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

func (e Error) Error() string {
	return e.Message
}

var ErrInsufficientPermissions = NewError(http.StatusUnauthorized, "insufficient_permissions", "insufficient permissions")
var ErrUserNotFound = NewError(http.StatusNotFound, "user_not_found", "no such user")

var (
	ErrResourceNotFound               = NewError(http.StatusNotFound, "resource_not_found", "no such file or directory")
	ErrResourceNotCollection          = NewError(http.StatusMethodNotAllowed, "resource_not_collection", "cannot add member to non-collection resource")
	ErrResourceCollection             = NewError(http.StatusMethodNotAllowed, "resource_collection", "cannot write to collection resource")
	ErrResourceIDConflict             = NewError(http.StatusConflict, "resource_id_conflict", "resource id already exists")
	ErrResourceNameInvalid            = NewError(http.StatusBadRequest, "resource_name_invalid", "invalid name")
	ErrResourceNameConflict           = NewError(http.StatusPreconditionFailed, "resource_name_conflict", "resource name already exists")
	ErrResourceMoveTargetSubdirectory = NewError(http.StatusConflict, "move_target_subdirectory", "cannot move resource to its own subdirectory")
	ErrParentNotFound                 = NewError(http.StatusConflict, "parent_not_found", "parent not found")
)
