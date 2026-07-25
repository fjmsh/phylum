package command

import (
	"context"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"codeberg.org/shroff/phylum/server/internal/server"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"
)

func setupServeCommand() *cobra.Command {
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
		logger := zerolog.Ctx(cmd.Context())

		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT)
		closeWG := &sync.WaitGroup{}

		closeWG.Go(func() {
			steve.Get().Run(context.Background())
		})
		closeWG.Go(func() {
			server.Run()
		})

		<-sigChan

		logger.Info().Msg("Shutting Down")
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		go server.Shutdown(ctx)
		go steve.Get().Shutdown(ctx)

		closeWG.Wait()
	}

	return cmd
}
