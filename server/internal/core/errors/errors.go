package errors

import (
	"errors"
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

func (e Error) Error() string {
	return e.Message
}

func Is(err, target error) bool {
	return errors.Is(err, target)
}