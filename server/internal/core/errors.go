package core

import "net/http"

type Error struct {
	Status  int    `json:"status"`
	Code    string `json:"code"`
	Message string `json:"msg"`
}

func New(httpStatus int, code, msg string) error {
	return &Error{
		Status:  httpStatus,
		Code:    code,
		Message: msg,
	}
}

func (e Error) Error() string {
	return e.Message
}

var ErrInsufficientPermissions = New(http.StatusUnauthorized, "insufficient_permissions", "")
var ErrUserNotFound = New(http.StatusNotFound, "user_not_found", "no such user")

var (
	ErrResourceNotFound               = New(http.StatusNotFound, "resource_not_found", "no such file or directory")
	ErrResourceNotCollection          = New(http.StatusMethodNotAllowed, "resource_not_collection", "cannot add member to non-collection resource")
	ErrResourceCollection             = New(http.StatusMethodNotAllowed, "resource_collection", "cannot write to collection resource")
	ErrResourceIDConflict             = New(http.StatusConflict, "resource_id_conflict", "")
	ErrResourceNameInvalid            = New(http.StatusBadRequest, "resource_name_invalid", "name invalid")
	ErrResourceNameConflict           = New(http.StatusPreconditionFailed, "resource_name_conflict", "")
	ErrResourceMoveTargetSubdirectory = New(http.StatusConflict, "move_target_subdirectory", "cannot move resource to its own subdirectory")
	ErrParentNotFound                 = New(http.StatusConflict, "parent_not_found", "")
)
