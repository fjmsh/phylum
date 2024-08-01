package errors

import (
	"errors"
	"fmt"
)

type Err struct {
	Status  int    `json:"status"`
	Code    string `json:"code"`
	Details string `json:"details"`
}

func New(httpStatus int, code, details string) error {
	return &Err{
		Status:  httpStatus,
		Code:    code,
		Details: details,
	}
}

func (e *Err) Error() string {
	return fmt.Sprintf("%d %s (%s)", e.Status, e.Code, e.Details)
}

func Is(err, target error) bool {
	return errors.Is(err, target)
}
