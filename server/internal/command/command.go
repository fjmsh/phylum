package command

import (
	"context"
	"os"
	"path"
	"slices"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/command/admin"
	"codeberg.org/shroff/phylum/server/internal/command/admin/schema"
	"codeberg.org/shroff/phylum/server/internal/command/fs"
	"codeberg.org/shroff/phylum/server/internal/command/user"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"codeberg.org/shroff/phylum/server/internal/server"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/go-viper/mapstructure/v2"
	"github.com/google/uuid"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"
)

func SetupCommand() {
	var cmd = &cobra.Command{
		Use:     path.Base(os.Args[0]),
		Version: config.Version,
	}
	flags := cmd.PersistentFlags()
	logger := zerolog.New(os.Stderr).With().Timestamp().Logger()
	logger = logger.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: "15:04:05.999"})

	// Flags only. Not part of config file
	flags.StringP("workdir", "W", "", "Working Directory")
	flags.StringP("config", "c", "config.yml", "Config File Path")

	flags.Bool("debug", false, "Debug mode")
	flags.MarkHidden("debug")

	flags.Bool("db.trace", false, "Trace Database Queries")
	flags.MarkHidden("db.trace")

	flags.Bool("db.nomigrate", false, "Skip Database Migrations")
	flags.MarkHidden("db.nomigrate")

	uuid.EnableRandPool()
	cmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		if isCmd(cmd, "serve") {
			logger = logger.Level(zerolog.InfoLevel)
		} else {
			logger = logger.Level(zerolog.WarnLevel)
		}

		dir, _ := cmd.Flags().GetString("workdir")
		if dir != "" && dir != "." {
			logger.Debug().Str("dir", dir).Msg("Changing working directory")
			os.Chdir(dir)
		}

		if cmd.Name() == "init" {
			return
		}

		if err := config.Initialize(cmd); err != nil {
			logger.Fatal().Err(err).Msg("Failed to load config")
		} else if config.NeedsSetup() {
			if isCmd(cmd, "serve") {
				logger.Info().Msg("Server not yet configured")
			} else {
				logger.Fatal().Msg("Server is not yet configured. Please initialize using `init` or via web interface")
			}
		}

		var cfg Config
		var md mapstructure.Metadata
		err := config.Full.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf", DecoderConfig: &mapstructure.DecoderConfig{
			Result:           &cfg,
			WeaklyTypedInput: true,
			Metadata:         &md,
		}})
		if err != nil {
			panic(err)
		}

		if cfg.Debug {
			logger = logger.Level(zerolog.TraceLevel)
			logger.Debug().Msg("Running in debug mode")
			cfg.Server.Debug = true
		}
		unused := slices.DeleteFunc(md.Unused, func(e string) bool {
			return e == "workdir" || e == "config" || e == "image_tag"
		})
		if len(unused) != 0 {
			logger.Warn().Strs("keys", unused).Msg("Unused keys in config")
		}
		cmd.SetContext(logger.WithContext(cmd.Context()))

		schema.DBConfig = cfg.DB
		server.Initialize(cfg.Server, logger, config.NeedsSetup())

		if config.NeedsSetup() || isCmd(cmd, "schema") {
			// No need to do further setup
			return
		}

		ctx := context.Background()
		if pool, err := db.Initialize(ctx, cfg.DB, &logger); err != nil {
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
		if err := storage.Initialize(cfg.Storage, logger); err != nil {
			logger.Fatal().Err(err).Msg("failed to initialize storage")
		}
		if err := core.Initialize(db.Get(ctx), cfg.Core); err != nil {
			logger.Fatal().Err(err).Msg("failed to initialize core")
		}
		m := mail.CreateMailer(cfg.Mail, logger)
		mail.SetDefaultMailer(m)
		if m.Enabled() {
			if cfg.Mail.ConnectionCheckFatal {
				if err := m.CheckConnection(); err != nil {
					logger.Fatal().Err(err).Msg("mail connection check failed")
				}
			} else {
				go func() {
					if err := m.CheckConnection(); err != nil {
						logger.Warn().Err(err).Msg("mail connection check failed")
					}
				}()
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
		setupServeCommand(),
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
