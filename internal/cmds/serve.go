package cmds

import (
	"fmt"
	"time"

	webdav "github.com/emersion/go-webdav"
	"github.com/fvbock/endless"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/pgfs"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func setupServeCommand() *cobra.Command {
	var cmdServe = &cobra.Command{
		Use:   "serve",
		Short: "Run the server",
		Run: func(cmd *cobra.Command, args []string) {
			config := viper.GetViper()
			engine := createEngine(config.GetBool("cors_enabled"), config.GetStringSlice("cors_origins"))

			setupWebdav(engine.Group(config.GetString("webdav_prefix")))

			server := endless.NewServer(config.GetString("listen"), engine)
			server.BeforeBegin = func(addr string) {
				log.Info(fmt.Sprintf("Listening on %s\n", addr))
			}

			if err := server.ListenAndServe(); err != nil {
				log.Fatal(err.Error())
			}
		},
	}
	flags := cmdServe.Flags()

	flags.StringP("listen", "l", ":1234", "Listen Addres")
	viper.BindPFlag("listen", flags.Lookup("listen"))

	flags.Bool("cors-enabled", false, "CORS enabled")
	viper.BindPFlag("cors_enabled", flags.Lookup("cors-enabled"))

	flags.StringSlice("cors-origins", []string{"*"}, "CORS origins")
	viper.BindPFlag("cors_origins", flags.Lookup("cors-origins"))

	flags.String("webdav-prefix", "/webdav", "Listen Addres")
	viper.BindPFlag("webdav_prefix", flags.Lookup("webdav-prefix"))

	return cmdServe
}

func setupWebdav(r *gin.RouterGroup) {
	log.Info(fmt.Sprintf("Setting up WebDAV access at %s", r.BasePath()))

	cs, err := pgfs.NewLocalFsContentStore("srv")
	if err != nil {
		panic(err)
	}
	webdavHandler := webdav.Handler{
		FileSystem: pgfs.New(queries, cs, r.BasePath()),
	}
	handler := func(c *gin.Context) {
		webdavHandler.ServeHTTP(c.Writer, c.Request)
	}
	r.Handle("OPTIONS", "/*path", handler)
	r.Handle("GET", "/*path", handler)
	r.Handle("PUT", "/*path", handler)
	r.Handle("HEAD", "/*path", handler)
	r.Handle("POST", "/*path", handler)
	r.Handle("DELETE", "/*path", handler)
	r.Handle("MOVE", "/*path", handler)
	r.Handle("COPY", "/*path", handler)
	r.Handle("PROPFIND", "/*path", handler)
	r.Handle("PROPPATCH", "/*path", handler)
}

func createEngine(corsEnabled bool, corsOrigins []string) *gin.Engine {
	if !debugMode {
		gin.SetMode(gin.ReleaseMode)
	}
	engine := gin.Default()

	if corsEnabled {
		engine.Use(cors.New(cors.Config{
			AllowOrigins:     corsOrigins,
			AllowHeaders:     []string{"Origin", "Authorization", "Accept", "Accept-Language", "Content-Type"},
			AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "PROPFIND", "PROPPATCH", "COPY", "MOVE"},
			ExposeHeaders:    []string{"Content-Length"},
			AllowWebSockets:  true,
			AllowCredentials: true,
			MaxAge:           24 * time.Hour,
		}))
	}

	return engine
}
