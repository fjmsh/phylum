package errors

import (
	"errors"
	"fmt"

	"github.com/gin-gonic/gin"
)

type ApiErr struct {
	Status  int    `json:"status"`
	Code    string `json:"code"`
	Details string `json:"details"`
}

func New(httpStatus int, code, details string) error {
	return &ApiErr{
		Status:  httpStatus,
		Code:    code,
		Details: details,
	}
}

func (e *ApiErr) Error() string {
	return fmt.Sprintf("%d %s (%s)", e.Status, e.Code, e.Details)
}

func Is(err, target error) bool {
	return errors.Is(err, target)
}

func RecoverApiError(c *gin.Context) {
	defer func() {
		if err := recover(); err != nil {
			if e, ok := err.(*ApiErr); ok {
				c.AbortWithStatusJSON(e.Status, e)
			} else {
				panic(err)
			}
		}
	}()
	c.Next()
}
