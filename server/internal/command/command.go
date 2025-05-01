package command

import (
	"os"
	"path"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/command/fs"
	"github.com/shroff/phylum/server/internal/command/publink"
	"github.com/shroff/phylum/server/internal/command/schema"
	"github.com/shroff/phylum/server/internal/command/serve"
	storagecmd "github.com/shroff/phylum/server/internal/command/storage"
	"github.com/shroff/phylum/server/internal/command/trash"
	"github.com/shroff/phylum/server/internal/command/user"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() {
	viper.SetEnvPrefix("phylum")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	var rootCmd = &cobra.Command{Use: path.Base(os.Args[0])}
	flags := rootCmd.PersistentFlags()

	flags.StringP("workdir", "W", "", "Set working directory")

	flags.Bool("debug", false, "Debug mode")
	flags.MarkHidden("debug")
	viper.BindPFlag("debug", flags.Lookup("debug"))

	flags.Bool("trace-queries", false, "Trace Database Queries")
	flags.MarkHidden("trace-queries")

	viper.SetDefault("db.host", "localhost")
	viper.SetDefault("db.port", "5432")
	viper.SetDefault("db.name", "phylum")
	viper.SetDefault("db.user", "phylum")
	viper.SetDefault("db.trace_queries", "false")
	viper.SetDefault("db.skip_migration", "false")

	viper.SetDefault("storage.default_dir", "storage/default")

	uuid.EnableRandPool()
	rootCmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		dir, _ := cmd.Flags().GetString("workdir")
		if dir != "" && dir != "." {
			logrus.Info("Changing directory to " + dir)
			os.Chdir(dir)
		}
		if viper.GetBool("debug") {
			logrus.SetLevel(logrus.TraceLevel)
			logrus.Debug("Running in debug mode")
		}

		db.Config = viper.Sub("db")
		// TODO: Hack. flag bindings don't work in viper for nested keys
		db.Config.BindPFlag("trace_queries", flags.Lookup("trace-queries"))
		storage.Config = viper.Sub("storage")
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
