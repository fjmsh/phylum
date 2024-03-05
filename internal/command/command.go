package command

import (
	"context"
	"os"
	"path"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/vfs"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var debug bool = false
var vfsManager vfs.VfsManager

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

	var conn *pgx.Conn

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
		config, err := pgx.ParseConfig(dsn)

		if viper.GetBool("trace_sql") {
			config.Tracer = phylumTracer{}
		}

		if err != nil {
			logrus.Fatal("Unable to parse db connection String: " + err.Error())
		}
		conn, err = pgx.ConnectConfig(context.Background(), config)
		if err != nil {
			logrus.Fatal("Unable to connect to database: " + err.Error())
		}
		vfsManager = vfs.NewManager(conn)
	}

	defer func() {
		if conn != nil {
			logrus.Info("Closing datbase connection")
			conn.Close(context.Background())
		}
	}()

	rootCmd.AddCommand([]*cobra.Command{
		setupServeCommand(),
		setupAdminCommand(),
	}...)
	rootCmd.Execute()
}

type phylumTracer struct {
}

func (p phylumTracer) TraceQueryStart(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryStartData) context.Context {
	logrus.Trace(data)
	return ctx
}

func (p phylumTracer) TraceQueryEnd(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryEndData) {
	logrus.Trace(data)
}
