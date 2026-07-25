package server

import (
	"context"
	"net"
	"net/http"
	"strconv"
	"time"

	"codeberg.org/shroff/phylum/server/internal/api/publink"
	apiv1 "codeberg.org/shroff/phylum/server/internal/api/v1"
	"codeberg.org/shroff/phylum/server/internal/api/v1/user"
	"codeberg.org/shroff/phylum/server/internal/api/webdav"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

type server struct {
	cfg        Config
	logger     zerolog.Logger
	needsSetup bool
	engine     *gin.Engine
	server     *http.Server
}

var s *server

func Initialize(cfg Config, logger zerolog.Logger, needsSetup bool) {
	s = &server{cfg: cfg, logger: logger.With().Str("mod", "server").Logger(), needsSetup: needsSetup}
}

func Run() error {
	s.initializeEngine()
	s.setupRoutes()
	s.setupWebApp()
	return s.listen()
}

func Shutdown(ctx context.Context) error {
	return s.server.Shutdown(ctx)
}

func (s *server) setupRoutes() {
	apiv1.Setup(s.engine.Group("/api/v1"), s.needsSetup, &s.logger)
	if !s.needsSetup {
		if s.cfg.WebDAV.Enabled {
			r := s.engine.Group(s.cfg.WebDAV.Path)
			webdav.SetupHandler(r)
			s.logger.Info().Str("path", r.BasePath()).Msg("WebDAV Enabled")
		}
		publink.Setup(s.engine.Group(s.cfg.PublinkPath))
		user.InitBootstrapConfig(s.cfg.PublinkPath)
		core.SetupTrashCompactor(&s.logger)
	}
}

func (s *server) listen() error {
	listen := s.cfg.Host + ":" + strconv.Itoa(s.cfg.Port)
	s.server = &http.Server{
		Addr:              listen,
		Handler:           s.engine,
		ReadHeaderTimeout: 10 * time.Second,
	}

	ln, err := net.Listen("tcp", listen)
	if err != nil {
		s.logger.Fatal().Err(err).Str("address", listen).Msg("Failed to listen")
	}
	s.logger.Info().Str("address", listen).Msg("Listening")

	return s.server.Serve(ln)
}
