package command

import (
	"embed"
	"errors"
	"os"
	"path"
	"strings"

	"github.com/google/uuid"
	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/env"
	"github.com/knadh/koanf/providers/file"
	"github.com/knadh/koanf/providers/posflag"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/v2"
	"github.com/shroff/phylum/server/internal/command/fs"
	"github.com/shroff/phylum/server/internal/command/publink"
	"github.com/shroff/phylum/server/internal/command/schema"
	"github.com/shroff/phylum/server/internal/command/serve"
	storagecmd "github.com/shroff/phylum/server/internal/command/storage"
	"github.com/shroff/phylum/server/internal/command/trash"
	"github.com/shroff/phylum/server/internal/command/user"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/mail"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

//go:embed config.defaults.yml
var defaultConfig embed.FS

func SetupCommand() {
	var rootCmd = &cobra.Command{Use: path.Base(os.Args[0])}
	flags := rootCmd.PersistentFlags()

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
		logrus.Fatal(err.Error())
	} else {
		if err := k.Load(rawbytes.Provider(bytes), yaml.Parser()); err != nil {
			logrus.Fatal("Unable to default load config: ", err.Error())
		}
	}

	uuid.EnableRandPool()
	rootCmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		dir, _ := cmd.Flags().GetString("workdir")
		if dir != "" && dir != "." {
			logrus.Info("Changing directory to " + dir)
			os.Chdir(dir)
		}

		configFile, _ := cmd.Flags().GetString("config-file")
		if configFile != "" {
			if err := k.Load(file.Provider(configFile), yaml.Parser()); err != nil {
				if errors.Is(err, os.ErrNotExist) {
					logrus.Info("Config file does not exist. Skipping")
				} else {
					logrus.Fatal("Unable to load config: ", err.Error())
				}
			} else {
				logrus.Info("Loaded config from ", configFile)
			}
		}

		if err := k.Load(posflag.ProviderWithFlag(cmd.Flags(), ".", k, func(f *pflag.Flag) (string, interface{}) {
			if !f.Changed {
				return "", ""
			}
			k, v := strings.ReplaceAll(f.Name, "_", "."), posflag.FlagVal(cmd.Flags(), f)
			return k, v
		}), nil); err != nil {
			logrus.Fatalf("Unable to load flags: %v", err)
		}

		k.Load(env.Provider("PHYLUM_", ".", func(s string) string {
			return strings.Replace(strings.ToLower(
				strings.TrimPrefix(s, "PHYLUM_")), "_", ".", -1)
		}), nil)

		var cfg Config
		k.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf"})

		if cfg.Debug {
			logrus.SetLevel(logrus.TraceLevel)
			logrus.Debug("Running in debug mode")
			cfg.Server.Debug = true
		}

		db.Cfg = cfg.DB
		storage.Cfg = cfg.Storage
		serve.Cfg = cfg.Server
		mail.Cfg = cfg.Mail
	}

	defer func() {
		logrus.Debug("Shutting Down App")
		db.Close()
	}()

	rootCmd.AddGroup(&cobra.Group{
		ID:    "admin",
		Title: "Admin",
	})
	rootCmd.AddCommand(
		schema.SetupCommand(),
		user.SetupCommand(),
		storagecmd.SetupCommand(),
	)

	rootCmd.AddGroup(&cobra.Group{
		ID:    "app",
		Title: "App",
	})
	rootCmd.AddCommand(
		fs.SetupCommand(),
		publink.SetupCommand(),
		trash.SetupCommand(),
	)

	rootCmd.AddGroup(&cobra.Group{
		ID:    "server",
		Title: "Server",
	})
	rootCmd.AddCommand(serve.SetupCommand())

	rootCmd.Execute()
}
