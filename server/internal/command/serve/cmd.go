package serve

import (
	"context"
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
	"codeberg.org/shroff/phylum/server/internal/api/webdav"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

const trashRetainDuration = 30 * 24 * time.Hour

var Cfg Config

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
		engine := createEngine()

		if Cfg.WebDAV.Enabled {
			webdav.SetupHandler(engine.Group(Cfg.WebDAV.Path))
		}
		apiv1.Setup(engine.Group("/api/v1"))
		publink.Setup(engine.Group(Cfg.PublinkPath))

		setupWebApp(engine, "web")

		setupTrashCompactor()

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
					logrus.Fatal("Failed to start server: " + err.Error())
				}
			}
		}()

		closeWG.Add(1)
		go func() {
			defer closeWG.Done()
			if err := steve.Get().Run(context.Background()); err != nil {
				if !errors.Is(err, http.ErrServerClosed) {
					logrus.Fatal("Failed to start jobs client: " + err.Error())
				}
			}
		}()

		<-sigChan
		logrus.Info("Shutting Down")
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		go server.Shutdown(ctx)
		go steve.Get().Shutdown(ctx)

		closeWG.Wait()
	}

	return cmd
}

func setupWebApp(r gin.IRoutes, webAppSrcDir string) {
	fs := static.LocalFile(webAppSrcDir, false)
	fileserver := http.FileServer(fs)
	indexFilePath := path.Join(webAppSrcDir, "index.html")

	staticFileHandler := func(c *gin.Context) {
		path := c.Request.URL.Path
		if c.Request.Method == "GET" &&
			!strings.HasPrefix(path, "/api") &&
			!strings.HasPrefix(path, Cfg.WebDAV.Path) &&
			!strings.HasPrefix(path, Cfg.PublinkPath) {
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

func setupTrashCompactor() {
	ticker := time.NewTimer(24 * time.Hour)
	go func() {
		for {
			<-ticker.C
			core.TrashCompact(context.Background(), trashRetainDuration)
		}
	}()
	core.TrashCompact(context.Background(), trashRetainDuration)
}
