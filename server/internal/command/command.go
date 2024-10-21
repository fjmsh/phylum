package command

import (
	"os"
	"path"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/command/fs"
	"github.com/shroff/phylum/server/internal/command/schema"
	"github.com/shroff/phylum/server/internal/command/serve"
	"github.com/shroff/phylum/server/internal/command/storage"
	"github.com/shroff/phylum/server/internal/command/user"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() {
	viper.SetEnvPrefix("phylum")

	var rootCmd = &cobra.Command{Use: path.Base(os.Args[0])}
	flags := rootCmd.PersistentFlags()

	flags.Bool("debug", false, "Debug mode")
	viper.BindPFlag("debug", flags.Lookup("debug"))

	flags.Bool("trace-sql", false, "Trace SQL Queries")
	viper.BindPFlag("trace_sql", flags.Lookup("trace-sql"))

	flags.StringP("working-dir", "W", "data", "Working Directory")
	viper.BindPFlag("working_dir", flags.Lookup("working-dir"))

	flags.String("database-url", "postgres://phylum:phylum@localhost:5432/phylum", "Database URL or DSN")
	viper.BindPFlag("database_url", flags.Lookup("database-url"))

	rootCmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		if viper.GetBool("debug") {
			logrus.SetLevel(logrus.TraceLevel)
			logrus.Debug("Running in debug mode")
		}

		workDir := viper.GetString("working_dir")
		if workDir != "." {
			logrus.Debug("Setting working directory to " + workDir)
			os.Mkdir(workDir, 0750)
			os.Chdir(workDir)
		}
	}

	defer func() {
		logrus.Debug("Shutting Down App")
		common.DB().Close()
	}()

	rootCmd.AddCommand([]*cobra.Command{
		schema.SetupCommand(),
		user.SetupCommand(),
		storage.SetupCommand(),
		fs.SetupCommand(),
		serve.SetupCommand(),
	}...)
	rootCmd.Execute()
}
