package server

import (
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func (s *server) initializeEngine() {
	if !s.cfg.Debug {
		gin.SetMode(gin.ReleaseMode)
	}

	s.engine = gin.New()
	s.engine.Use(gin.Logger(), gin.CustomRecovery(func(c *gin.Context, err any) {
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"status": 500,
			"code":   "internal_server_error",
			"msg":    "Internal Server Error",
		})
	}))
	if s.cfg.LogBody {
		s.engine.Use(createLogBodyMiddleware(s.logger))
	}

	if s.cfg.CORS.Enabled {
		origins := s.cfg.CORS.Origins
		s.logger.Info().Strs("origins", origins).Msg("Enabling CORS")
		s.engine.Use(cors.New(cors.Config{
			AllowOrigins:     origins,
			AllowHeaders:     []string{"Origin", "Authorization", "Accept", "Accept-Language", "Content-Type", "X-Device"},
			AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "PROPFIND", "PROPPATCH", "COPY", "MOVE"},
			ExposeHeaders:    []string{"Content-Length"},
			AllowWebSockets:  true,
			AllowCredentials: true,
			MaxAge:           24 * time.Hour,
		}))
	}

	s.engine.Use(func(c *gin.Context) {
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
}
