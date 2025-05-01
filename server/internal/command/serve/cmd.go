package serve

import (
	"context"
	"time"

	"github.com/fvbock/endless"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/shroff/phylum/server/internal/api/publink"
	apiv1 "github.com/shroff/phylum/server/internal/api/v1"
	"github.com/shroff/phylum/server/internal/api/webdav"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const trashRetainDuration = 30 * 24 * time.Hour

func SetupCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:     "serve",
		Short:   "Run the server",
		GroupID: "server",
		Run: func(cmd *cobra.Command, args []string) {
			config := viper.Sub("server")

			flags := cmd.Flags()
			// TODO: Hack. flag bindings don't work in viper for nested keys
			config.BindPFlag("web_app_dir", flags.Lookup("web-app-dir"))
			config.BindPFlag("host", flags.Lookup("host"))
			config.BindPFlag("port", flags.Lookup("port"))
			config.BindPFlag("log_body", flags.Lookup("log-body"))
			config.BindPFlag("cors.enabled", flags.Lookup("cors-enabled"))
			config.BindPFlag("cors.origins", flags.Lookup("cors-origins"))
			config.BindPFlag("webdav_prefix", flags.Lookup("webdav-prefix"))

			if !viper.GetBool("debug") {
				gin.SetMode(gin.ReleaseMode)
			}
			engine := createEngine(config)

			webdav.SetupHandler(engine.Group(config.GetString("webdav_prefix")))
			apiv1.Setup(engine.Group("/api/v1"))
			publink.Setup(engine.Group("/publink"))

			webAppDir := config.GetString("web_app_dir")
			if webAppDir != "" {
				engine.Use(func(c *gin.Context) {
					c.Writer.Header().Set("Cross-Origin-Embedder-Policy", "credentialless")
					c.Writer.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
				}, static.Serve("/", static.LocalFile(webAppDir, false)))
			}
			setupTrashCompactor()

			listen := config.GetString("host") + ":" + config.GetString("port")
			server := endless.NewServer(listen, engine)
			server.BeforeBegin = func(addr string) {
				logrus.Info("Listening on " + addr)
			}

			if err := server.ListenAndServe(); err != nil {
				logrus.Fatal(err.Error())
			}
		},
	}
	flags := cmd.Flags()

	flags.String("web-app-dir", "web", "Web App Directory")
	flags.String("host", "", "Server Host")
	flags.String("port", "2448", "Server Port")
	flags.Bool("log-body", false, "Log Response Body (Must be used with --debug)")
	flags.Bool("cors-enabled", false, "Enable CORS")
	flags.StringSlice("cors-origins", []string{"*"}, "CORS origins")
	flags.String("webdav-prefix", "/webdav", "Listen Addres")

	// Must be specified otherwise env variables won't be parsed
	viper.SetDefault("server.host", "")
	viper.SetDefault("server.port", "2448")
	viper.SetDefault("server.log_body", false)
	viper.SetDefault("server.cors.enabled", false)
	viper.SetDefault("server.cors.origins", []string{"*"})
	viper.SetDefault("server.webdav_prefix", "/webdav")

	return cmd
}

func setupTrashCompactor() {
	ticker := time.NewTimer(24 * time.Hour)
	go func() {
		for {
			<-ticker.C
			fs.TrashCompact(context.Background(), trashRetainDuration)
		}
	}()
	fs.TrashCompact(context.Background(), trashRetainDuration)
}
