package serve

import (
	"context"
	"errors"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"
	"time"

	"codeberg.org/shroff/phylum/server/internal/steve"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func run(engine *gin.Engine, logger *zerolog.Logger) {
	listen := Cfg.Host + ":" + strconv.Itoa(Cfg.Port)
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT)
	closeWG := &sync.WaitGroup{}

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

	server := http.Server{
		Addr:              listen,
		Handler:           engine,
		ReadHeaderTimeout: 10 * time.Second,
	}
	closeWG.Add(1)
	go func() {
		defer closeWG.Done()

		ln, err := net.Listen("tcp", listen)
		if err != nil {
			logger.Fatal().Err(err).Str("address", listen).Msg("Failed to listen")
		}
		logger.Info().Str("address", listen).Msg("Listening")

		server.ListenAndServe()
		if err := server.Serve(ln); err != nil {
			if !errors.Is(err, http.ErrServerClosed) {
				logger.Fatal().Err(err).Msg("Server stopped unexpectedly")
			}
		}
	}()

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
