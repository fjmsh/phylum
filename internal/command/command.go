package command

import (
	"context"
	"os"
	"path"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/shroff/phylum/server/internal/user"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var debug bool = false
var fs *core.FileSystem
var userManager *user.Manager
var storageManager *storage.Manager

func SetupCommand() {
	viper.SetEnvPrefix("phylum")

	var rootCmd = &cobra.Command{Use: path.Base(os.Args[0])}
	flags := rootCmd.PersistentFlags()

	flags.BoolP("debug", "d", false, "Debug mode")
	viper.BindPFlag("debug", flags.Lookup("debug"))

	flags.Bool("trace-sql", false, "Trace SQL Queries")
	viper.BindPFlag("trace_sql", flags.Lookup("trace-sql"))

	flags.StringP("working-dir", "W", ".", "Working Directory")
	viper.BindPFlag("working_dir", flags.Lookup("working-dir"))

	flags.String("database-url", "postgres://phylum:phylum@localhost:5432/phylum", "Database URL or DSN")
	viper.BindPFlag("database_url", flags.Lookup("database-url"))

	var db *sql.DbHandler

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

		dsn := viper.GetString("database_url")

		var err error
		db, err = sql.NewDb(dsn, debug && viper.GetBool("trace_sql"))
		if err != nil {
			logrus.Fatal(err)
		}

		userManager, err = user.NewManager(db)
		if err != nil {
			logrus.Fatal(err)
		}
		storageManager, err = storage.NewManager(db)
		if err != nil {
			logrus.Fatal(err)
		}
		fs, err = core.OpenFileSystem(db, storageManager)
		if err != nil {
			logrus.Fatal(err)
		}
	}

	defer func() {
		if db != nil {
			logrus.Info("Closing datbase connection")
			db.Close(context.Background())
		}
	}()

	rootCmd.AddCommand([]*cobra.Command{
		setupServeCommand(),
		setupAdminCommand(),
	}...)
	rootCmd.Execute()
}
