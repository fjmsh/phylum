package command

import (
	"context"
	"errors"
	"os"
	"path"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/command/admin"
	"codeberg.org/shroff/phylum/server/internal/command/admin/schema"
	"codeberg.org/shroff/phylum/server/internal/command/fs"
	"codeberg.org/shroff/phylum/server/internal/command/serve"
	"codeberg.org/shroff/phylum/server/internal/command/user"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"
)

func SetupCommand() {
	var cmd = &cobra.Command{
		Use:     path.Base(os.Args[0]),
		Version: "0.8.0",
	}
	flags := cmd.PersistentFlags()
	logger := zerolog.New(os.Stderr).With().Timestamp().Logger()
	logger = logger.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: "15:04:05.999"})

	// Flags only. Not part of config file
	flags.StringP("workdir", "W", "", "Working Directory")
	flags.StringP("config-file", "c", "config.yml", "Config File Path")

	flags.Bool("debug", false, "Debug mode")
	flags.MarkHidden("debug")

	flags.Bool("db_trace", false, "Trace Database Queries")
	flags.MarkHidden("db_trace")

	flags.Bool("db_nomigrate", false, "Skip Database Migrations")
	flags.MarkHidden("db_nomigrate")

	uuid.EnableRandPool()
	cmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		if isCmd(cmd, "serve") {
			logger = logger.Level(zerolog.InfoLevel)
		} else {
			logger = logger.Level(zerolog.WarnLevel)
		}

		dir, _ := cmd.Flags().GetString("workdir")
		if dir != "" && dir != "." {
			logger.Info().Str("dir", dir).Msg("Changing working directory")
			os.Chdir(dir)
		}

		if cmd.Name() == "init" {
			return
		}

		k := koanf.New(".")

		// Default config
		if kDefault, err := config.LoadDefault(); err != nil {
			logger.Fatal().Err(err).Msg("Failed to load default config")
		} else {
			k.Merge(kDefault)
		}

		// Instance config
		configFile, _ := cmd.Flags().GetString("config-file")
		if kServer, err := config.LoadFile(configFile); err != nil {
			if errors.Is(err, os.ErrNotExist) {
				if isCmd(cmd, "serve") {
					logger.Info().Msg("Server not yet configured")
					serve.NeedsConfig = true
				} else {
					logger.Fatal().Msg("Server is not yet configured. Please initialize using `init` or via web interface")
				}
			} else {
				logger.Fatal().Err(err).Msg("Failed to load config")
			}
		} else {
			k.Merge(kServer)
		}

		// Flags
		if kFlags, err := config.LoadFlags(cmd); err != nil {
			logger.Fatal().Err(err).Msg("Failed to load flags")
		} else {
			k.Merge(kFlags)
		}

		// Environment variables
		k.Merge(config.LoadEnv())

		var cfg config.Config
		k.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf"})

		if cfg.Debug {
			logger = logger.Level(zerolog.TraceLevel)
			logger.Debug().Msg("Running in debug mode")
			cfg.Server.Debug = true
		}
		cmd.SetContext(logger.WithContext(cmd.Context()))

		serve.Cfg = cfg.Server
		schema.DBConfig = cfg.DB

		if serve.NeedsConfig || isCmd(cmd, "schema") {
			// No need to do further setup
			return
		}

		ctx := context.Background()
		if pool, err := db.Initialize(ctx, cfg.DB, logger); err != nil {
			logger.Fatal().Err(err).Msg("failed to initialize db pool")
		} else {
			pubsub.Initialize(ctx, pool, logger)

			client := steve.Initialize(db.Get(ctx), cfg.Steve, logger)
			steve.RegisterWorker(client, &jobs.MigrateWorker{})
			steve.RegisterWorker(client, &jobs.CopyImgsWorker{})
			steve.RegisterWorker(client, &jobs.CopyContentsWorker{})
			steve.RegisterWorker(client, &jobs.DeleteContentsWorker{})
			steve.RegisterWorker(client, &jobs.GenerateImgsWorker{})
		}

		// storage must be initialiezd before core
		if err := storage.Initialize(db.Get(ctx), cfg.Storage, logger); err != nil {
			logger.Fatal().Err(err).Msg("failed to initialize storage")
		}
		if err := core.Initialize(db.Get(ctx), cfg.Core); err != nil {
			logger.Fatal().Err(err).Msg("failed to initialize core")
		}
		if err := mail.Initialize(cfg.Mail, logger); err != nil {
			if errors.Is(err, mail.ErrEmailNotConfigured) {
				logger.Info().Msg("mail not configured")
			} else {
				logger.Fatal().Err(err).Msg("failed to initialize mail")
			}
		}
		if err := auth.Initialize(cfg.Auth, logger); err != nil {
			logger.Fatal().Err(err)
		}
	}

	defer func() {
		db.Close()
	}()

	cmd.AddCommand(
		admin.SetupCommand(),
		fs.SetupCommand(),
		user.SetupCommand(),
		serve.SetupCommand(),
		setupInitCommand(),
	)
	cmd.AddGroup(&cobra.Group{ID: "misc", Title: "Misc"})
	cmd.SetHelpCommandGroupID("misc")
	cmd.SetCompletionCommandGroupID("misc")
	cmd.Execute()
}

func isCmd(cmd *cobra.Command, s string) bool {
	for c := cmd; c != nil; c = c.Parent() {
		if c.Name() == s {
			return true
		}
	}
	return false
}
