package command

import (
	"context"
	"embed"
	"errors"
	"os"
	"path"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/command/admin"
	"codeberg.org/shroff/phylum/server/internal/command/admin/schema"
	"codeberg.org/shroff/phylum/server/internal/command/fs"
	"codeberg.org/shroff/phylum/server/internal/command/serve"
	"codeberg.org/shroff/phylum/server/internal/command/user"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/env"
	"github.com/knadh/koanf/providers/file"
	"github.com/knadh/koanf/providers/posflag"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

//go:embed config.defaults.yml
var defaultConfig embed.FS

func SetupCommand() {
	var cmd = &cobra.Command{
		Use:     path.Base(os.Args[0]),
		Version: "0.6.0",
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

	k := koanf.New(".")
	if bytes, err := defaultConfig.ReadFile("config.defaults.yml"); err != nil {
		logger.Fatal().Err(err).Msg("failed to read default config file")
	} else {
		if err := k.Load(rawbytes.Provider(bytes), yaml.Parser()); err != nil {
			logger.Fatal().Err(err).Msg("failed to load default config")
		}
	}

	uuid.EnableRandPool()
	cmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		if cmd.Name() == "serve" {
			logger = logger.Level(zerolog.InfoLevel)
		} else {
			logger = logger.Level(zerolog.WarnLevel)
		}

		dir, _ := cmd.Flags().GetString("workdir")
		if dir != "" && dir != "." {
			logger.Info().Str("dir", dir).Msg("Changing working directory")
			os.Chdir(dir)
		}

		configFile, _ := cmd.Flags().GetString("config-file")
		if configFile != "" {
			if err := k.Load(file.Provider(configFile), yaml.Parser()); err != nil {
				if errors.Is(err, os.ErrNotExist) {
					logger.Info().Msg("config file does not exist. Skipping")
				} else {
					logger.Fatal().Err(err).Msg("failed to load config")
				}
			} else {
				logger.Info().Msg("loaded config")
			}
		}

		if err := k.Load(posflag.ProviderWithFlag(cmd.Flags(), ".", k, func(f *pflag.Flag) (string, interface{}) {
			if !f.Changed {
				return "", ""
			}
			k, v := strings.ReplaceAll(f.Name, "_", "."), posflag.FlagVal(cmd.Flags(), f)
			return k, v
		}), nil); err != nil {
			logger.Fatal().Err(err).Msg("failed to load flags")
		}

		k.Load(env.Provider("PHYLUM_", ".", func(s string) string {
			return strings.Replace(strings.ToLower(
				strings.TrimPrefix(s, "PHYLUM_")), "_", ".", -1)
		}), nil)

		var cfg Config
		k.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf"})

		if cfg.Debug {
			logger = logger.Level(zerolog.TraceLevel)
			logger.Debug().Msg("Running in debug mode")
			cfg.Server.Debug = true
		}
		cmd.SetContext(logger.WithContext(cmd.Context()))

		serve.Cfg = cfg.Server
		schema.DBConfig = cfg.DB

		if isCmd(cmd, "schema") {
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
