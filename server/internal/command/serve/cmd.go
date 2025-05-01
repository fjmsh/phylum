package serve

import (
	"context"
	"time"

	"github.com/fvbock/endless"
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
				}).Static("/", webAppDir)
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
	viper.BindPFlag("server.web_app_dir", flags.Lookup("web-app-dir"))
	viper.SetDefault("server.web_app_dir", "web")

	flags.String("server-host", "", "Server Host")
	viper.BindPFlag("server.host", flags.Lookup("server-host"))
	viper.SetDefault("server.host", "")
	flags.String("server-port", "2448", "Server Port")
	viper.BindPFlag("server.port", flags.Lookup("server-port"))
	viper.SetDefault("server.port", "2448")

	flags.Bool("log-body", false, "Log Response Body (Must be used with --debug)")
	viper.BindPFlag("server.log_body", flags.Lookup("log-body"))
	viper.SetDefault("server.log_body", false)

	flags.Bool("cors-enabled", false, "Enable CORS")
	viper.BindPFlag("server.cors.enabled", flags.Lookup("cors-enabled"))
	viper.SetDefault("server.cors.enabled", false)

	flags.StringSlice("cors-origins", []string{"*"}, "CORS origins")
	viper.BindPFlag("server.cors.origins", flags.Lookup("cors-origins"))
	viper.SetDefault("server.cors.origins", []string{"*"})

	flags.String("webdav-prefix", "/webdav", "Listen Addres")
	viper.BindPFlag("server.webdav_prefix", flags.Lookup("webdav-prefix"))
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
