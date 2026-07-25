package serve

import (
	"embed"

	"codeberg.org/shroff/phylum/server/internal/api/publink"
	apiv1 "codeberg.org/shroff/phylum/server/internal/api/v1"
	"codeberg.org/shroff/phylum/server/internal/api/v1/user"
	"codeberg.org/shroff/phylum/server/internal/api/webdav"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"
)

var Cfg Config
var NeedsConfig bool

//go:embed __static/**
var staticFS embed.FS

func SetupCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "serve",
		Short: "Run the server",
	}

	flags := cmd.Flags()

	flags.Bool("db.trace", false, "Trace Database Queries")
	flags.MarkHidden("db.trace")

	flags.String("server.host", "", "Server Host")
	flags.String("server.port", "", "Server Port")
	flags.String("server.web_app_src", "", "Web App Source Directory")
	flags.String("server.publink_path", "", "Public Share path prefix")
	flags.String("server.webdav.path", "", "WebDAV path prefix")
	flags.Bool("server.cors.enabled", false, "Enable CORS")
	flags.StringSlice("server.cors.origins", nil, "CORS origins")
	flags.Bool("server.log_body", false, "Log Response Body (Must be used with --debug)")

	cmd.Run = func(cmd *cobra.Command, args []string) {
		if !Cfg.Debug {
			gin.SetMode(gin.ReleaseMode)
		}
		logger := zerolog.Ctx(cmd.Context())
		engine := createEngine(logger)

		apiv1.Setup(engine.Group("/api/v1"), NeedsConfig, logger)
		if !NeedsConfig {
			if Cfg.WebDAV.Enabled {
				r := engine.Group(Cfg.WebDAV.Path)
				webdav.SetupHandler(r)
				logger.Info().Str("path", r.BasePath()).Msg("WebDAV Enabled")
			}
			publink.Setup(engine.Group(Cfg.PublinkPath))
			user.InitBootstrapConfig(Cfg.PublinkPath)
			core.SetupTrashCompactor(logger)
		}

		setupWebApp(engine, logger, Cfg.WebAppSrc)

		run(engine, logger)
	}

	return cmd
}
