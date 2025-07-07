package serve

import (
	"bytes"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type logBodyWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (w logBodyWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.ResponseWriter.Write(b)
}

func logBodyMiddleware(c *gin.Context) {
	logBodyWriter := &logBodyWriter{
		ResponseWriter: c.Writer,
		body:           bytes.NewBuffer(make([]byte, 0, 1024)),
	}
	c.Writer = logBodyWriter
	c.Next()
	log.Trace().Str("url", c.Request.URL.String()).Str("body", logBodyWriter.body.String()).Send()
}
