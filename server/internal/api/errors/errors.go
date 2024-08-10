package errors

import (
	"errors"
	"fmt"

	"github.com/gin-gonic/gin"
)

type ApiErr struct {
	Status  int    `json:"status"`
	Code    string `json:"code"`
	Message string `json:"msg"`
}

func New(httpStatus int, code, msg string) error {
	return &ApiErr{
		Status:  httpStatus,
		Code:    code,
		Message: msg,
	}
}

func (e *ApiErr) Error() string {
	return fmt.Sprintf("%d %s (%s)", e.Status, e.Code, e.Message)
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
