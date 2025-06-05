package serve

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
)

// func createEngine(logBody bool, corsEnabled bool, corsOrigins []string) *gin.Engine {
func createEngine() *gin.Engine {
	engine := gin.New()
	engine.Use(gin.Logger(), gin.CustomRecovery(func(c *gin.Context, err any) {
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"status": 500,
			"code":   "internal_server_error",
			"msg":    "Internal Server Error",
		})
	}))
	if Cfg.LogBody {
		engine.Use(logBodyMiddleware)
	}

	if Cfg.CORS.Enabled {
		origins := Cfg.CORS.Origins
		logrus.Info("Enabling cors (" + strings.Join(origins, ", ") + ")")
		engine.Use(cors.New(cors.Config{
			AllowOrigins:     origins,
			AllowHeaders:     []string{"Origin", "Authorization", "Accept", "Accept-Language", "Content-Type"},
			AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "PROPFIND", "PROPPATCH", "COPY", "MOVE"},
			ExposeHeaders:    []string{"Content-Length"},
			AllowWebSockets:  true,
			AllowCredentials: true,
			MaxAge:           24 * time.Hour,
		}))
	}

	engine.Use(func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				if e, ok := err.(*core.Error); ok {
					c.AbortWithStatusJSON(e.Status, e)
				} else {
					// This will be caught by the regular gin error recovery handler
					panic(err)
				}
			}
		}()
		c.Next()
	})

	return engine
}
