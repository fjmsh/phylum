package serve

import (
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

// func createEngine(logBody bool, corsEnabled bool, corsOrigins []string) *gin.Engine {
func createEngine(logger *zerolog.Logger) *gin.Engine {
	engine := gin.New()
	engine.Use(gin.Logger(), gin.CustomRecovery(func(c *gin.Context, err any) {
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"status": 500,
			"code":   "internal_server_error",
			"msg":    "Internal Server Error",
		})
	}))
	if Cfg.LogBody {
		engine.Use(createLogBodyMiddleware(logger))
	}

	if Cfg.CORS.Enabled {
		origins := Cfg.CORS.Origins
		logger.Info().Strs("origins", origins).Msg("Enabling CORS")
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
