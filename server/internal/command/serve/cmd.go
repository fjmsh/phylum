package serve

import (
	"context"
	"embed"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"path"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"codeberg.org/shroff/phylum/server/internal/api/publink"
	apiv1 "codeberg.org/shroff/phylum/server/internal/api/v1"
	"codeberg.org/shroff/phylum/server/internal/api/v1/user"
	"codeberg.org/shroff/phylum/server/internal/api/webdav"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"
)

const trashRetainDuration = 30 * 24 * time.Hour

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

	flags.Bool("db_trace", false, "Trace Database Queries")
	flags.MarkHidden("db_trace")

	flags.String("server_host", "", "Server Host")
	flags.String("server_port", "", "Server Port")
	flags.String("server_webappsrc", "", "Web App Source Directory")
	flags.String("server_publinkpath", "", "Public Share path prefix")
	flags.String("server_webdavpath", "", "WebDAV path prefix")
	flags.Bool("server_cors_enabled", false, "Enable CORS")
	flags.StringSlice("server_cors_origins", nil, "CORS origins")
	flags.Bool("server_logbody", false, "Log Response Body (Must be used with --debug)")

	cmd.Run = func(cmd *cobra.Command, args []string) {
		if !Cfg.Debug {
			gin.SetMode(gin.ReleaseMode)
		}
		logger := zerolog.Ctx(cmd.Context())
		engine := createEngine(logger)

		if NeedsConfig {
			apiv1.SetupConfig(engine.Group("/api/v1"), logger)
		} else {
			if Cfg.WebDAV.Enabled {
				r := engine.Group(Cfg.WebDAV.Path)
				webdav.SetupHandler(r)
				logger.Info().Str("path", r.BasePath()).Msg("WebDAV Enabled")
			}
			apiv1.Setup(engine.Group("/api/v1"), logger)
			publink.Setup(engine.Group(Cfg.PublinkPath))
			user.InitBootstrapConfig(Cfg.PublinkPath)

			setupTrashCompactor(logger)
		}

		setupWebApp(engine, logger, Cfg.WebAppSrc)

		listen := Cfg.Host + ":" + strconv.Itoa(Cfg.Port)
		server := http.Server{
			Addr:              listen,
			Handler:           engine,
			ReadHeaderTimeout: 10 * time.Second,
		}

		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT)
		closeWG := &sync.WaitGroup{}

		closeWG.Add(1)
		go func() {
			defer closeWG.Done()
			if err := server.ListenAndServe(); err != nil {
				if !errors.Is(err, http.ErrServerClosed) {
					logger.Fatal().Err(err).Msg("failed to start server")
				}
			}
		}()

		if !NeedsConfig {
			closeWG.Add(1)
			go func() {
				defer closeWG.Done()
				if err := steve.Get().Run(context.Background()); err != nil {
					if !errors.Is(err, steve.ErrShutdown) {
						logger.Fatal().Err(err).Msg("failed to start jobs")
					}
				}
			}()
		}

		<-sigChan
		logger.Info().Msg("Shutting Down")
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		go server.Shutdown(ctx)
		if !NeedsConfig {
			go steve.Get().Shutdown(ctx)
		}

		closeWG.Wait()
	}

	return cmd
}

func setupWebApp(r gin.IRoutes, logger *zerolog.Logger, webAppSrcDir string) {
	fs := static.LocalFile(webAppSrcDir, false)
	fileserver := http.FileServer(fs)

	if !fs.Exists("/", "/index.html") {
		logger.Warn().Msg("Unable to locate Web App at `" + webAppSrcDir + "`. " +
			"It may not be built or be configured incorrectly.")
		fs = nil
		fileserver = nil
	}
	indexFilePath := path.Join(webAppSrcDir, "index.html")

	staticFS, err := static.EmbedFolder(staticFS, ".")
	if err != nil {
		panic(err)
	}
	staticFileSserver := http.FileServer(staticFS)

	webdavPath := Cfg.WebDAV.Path
	if !strings.HasSuffix(webdavPath, "/'") {
		webdavPath += "/"
	}

	publinkPath := Cfg.PublinkPath
	if !strings.HasSuffix(webdavPath, "/'") {
		publinkPath += "/"
	}

	staticFileHandler := func(c *gin.Context) {
		path := c.Request.URL.Path
		if strings.HasPrefix(path, "/__static") && staticFS.Exists("/", c.Request.URL.Path) {
			staticFileSserver.ServeHTTP(c.Writer, c.Request)
			return
		}

		if fs != nil && c.Request.Method == "GET" &&
			!strings.HasPrefix(path, "/api") &&
			!strings.HasPrefix(path, webdavPath) &&
			!strings.HasPrefix(path, publinkPath) {
			c.Writer.Header().Set("Cross-Origin-Embedder-Policy", "credentialless")
			c.Writer.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
			if fs.Exists("/", c.Request.URL.Path) {
				fileserver.ServeHTTP(c.Writer, c.Request)
			} else {
				http.ServeFile(c.Writer, c.Request, indexFilePath)
			}
		} else {
			c.JSON(http.StatusNotFound, gin.H{
				"status": 404,
				"code":   "route_not_found",
				"msg":    "Route Not Found",
			})
		}
	}
	r.Use(staticFileHandler)
}

func setupTrashCompactor(logger *zerolog.Logger) {
	ticker := time.NewTimer(24 * time.Hour)
	go func() {
		for {
			<-ticker.C
			core.TrashCompact(context.Background(), logger, trashRetainDuration)
		}
	}()
	core.TrashCompact(context.Background(), logger, trashRetainDuration)
}
