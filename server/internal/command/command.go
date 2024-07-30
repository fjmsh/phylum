package command

import (
	"os"
	"path"

	"github.com/shroff/phylum/server/internal/app"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var debug bool = false

func SetupCommand() {
	viper.SetEnvPrefix("phylum")

	var rootCmd = &cobra.Command{Use: path.Base(os.Args[0])}
	flags := rootCmd.PersistentFlags()

	flags.BoolP("debug", "d", false, "Debug mode")
	viper.BindPFlag("debug", flags.Lookup("debug"))

	flags.Bool("trace-sql", false, "Trace SQL Queries")
	viper.BindPFlag("trace_sql", flags.Lookup("trace-sql"))

	flags.StringP("working-dir", "W", "data", "Working Directory")
	viper.BindPFlag("working_dir", flags.Lookup("working-dir"))

	flags.String("database-url", "postgres://phylum:phylum@localhost:5432/phylum", "Database URL or DSN")
	viper.BindPFlag("database_url", flags.Lookup("database-url"))

	flags.Bool("auto-migrate", false, "Automatically migrate database schema")
	viper.BindPFlag("auto_migrate", flags.Lookup("auto-migrate"))

	rootCmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		workDir := viper.GetString("working_dir")
		if workDir != "." {
			logrus.Info("Setting working directory to " + workDir)
			os.Mkdir(workDir, 0750)
			os.Chdir(workDir)
		}
		debug = viper.GetBool("debug")
		if debug {
			logrus.Info("Running in debug mode")
			logrus.SetLevel(logrus.TraceLevel)
		}

		if db, err := db.NewDb(viper.GetString("database_url"), debug && viper.GetBool("trace_sql"), viper.GetBool("auto_migrate")); err != nil {
			logrus.Fatal(err)
		} else if err := app.Initialize(db); err != nil {
			logrus.Fatal(err)
		}
	}

	defer func() {
		logrus.Info("Shutting Down App")
		app.Default.Cleanup()
	}()

	rootCmd.AddCommand([]*cobra.Command{
		setupServeCommand(),
		setupAdminCommand(),
	}...)
	rootCmd.Execute()
}
