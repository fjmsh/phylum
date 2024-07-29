package command

import (
	"bytes"
	"time"

	"github.com/fvbock/endless"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api"
	"github.com/shroff/phylum/server/internal/app"
	webdav "github.com/shroff/phylum/server/internal/handler_webdav"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func setupServeCommand() *cobra.Command {
	var cmdServe = &cobra.Command{
		Use:   "serve",
		Short: "Run the server",
		Run: func(cmd *cobra.Command, args []string) {
			config := viper.GetViper()
			engine := createEngine(config.GetBool("log_body"), config.GetBool("cors_enabled"), config.GetStringSlice("cors_origins"))

			webdav.SetupHandler(engine.Group(config.GetString("webdav_prefix")), app.Fs, app.UserManager)

			api.Setup(engine.Group("/api/v1"))

			server := endless.NewServer(config.GetString("listen"), engine)
			server.BeforeBegin = func(addr string) {
				logrus.Info("Listening on " + addr)
			}

			if err := server.ListenAndServe(); err != nil {
				logrus.Fatal(err.Error())
			}
		},
	}
	flags := cmdServe.Flags()

	flags.StringP("listen", "l", ":1234", "Listen Addres")
	viper.BindPFlag("listen", flags.Lookup("listen"))

	flags.Bool("log-body", false, "Log Response Body (Must be used with --debug)")
	viper.BindPFlag("log_body", flags.Lookup("log-body"))

	flags.Bool("cors-enabled", false, "Enabled CORS")
	viper.BindPFlag("cors_enabled", flags.Lookup("cors-enabled"))

	flags.StringSlice("cors-origins", []string{"*"}, "CORS origins")
	viper.BindPFlag("cors_origins", flags.Lookup("cors-origins"))

	flags.String("webdav-prefix", "/webdav", "Listen Addres")
	viper.BindPFlag("webdav_prefix", flags.Lookup("webdav-prefix"))

	return cmdServe
}

func createEngine(logBody bool, corsEnabled bool, corsOrigins []string) *gin.Engine {
	if !debug {
		gin.SetMode(gin.ReleaseMode)
	}
	engine := gin.Default()
	if debug && logBody {
		engine.Use(logBodyMiddleware)
	}

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
	logrus.Trace(c.Request.URL)
	logrus.Trace(logBodyWriter.body.String())
}
