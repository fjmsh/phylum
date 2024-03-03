package cmds

import (
	"context"
	"fmt"
	"os"
	"path"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/phylumfs"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var debugMode bool = false
var backend phylumfs.PhylumFs

func Setup() {
	viper.SetEnvPrefix("phylum")

	var rootCmd = &cobra.Command{Use: path.Base(os.Args[0])}
	flags := rootCmd.PersistentFlags()

	flags.BoolP("debug", "d", false, "Debug mode")
	viper.BindPFlag("debug", flags.Lookup("debug"))

	flags.StringP("working-dir", "W", ".", "Working Directory")
	viper.BindPFlag("working_dir", flags.Lookup("working-dir"))

	flags.String("database-url", "postgres://phylum:phylum@localhost:5432/phylum", "Database URL or DSN")
	viper.BindPFlag("database_url", flags.Lookup("database-url"))

	var conn *pgx.Conn

	rootCmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		workDir := viper.GetString("working_dir")
		if workDir != "." {
			log.Info(fmt.Sprintf("Setting working directory to %s", workDir))
			os.Mkdir(workDir, 0750)
			os.Chdir(workDir)
		}
		debugMode = viper.GetBool("debug")
		if debugMode {
			log.Info("Running in debug mode")
			log.SetLevel(log.TraceLevel)
		}

		dsn := viper.GetString("database_url")
		config, err := pgx.ParseConfig(dsn)
		if err != nil {
			log.Fatal(fmt.Sprintf("Unable to parse db connection String: %v\n", err))
		}
		if debugMode {
			config.Tracer = phylumTracer{}
		}
		conn, err = pgx.ConnectConfig(context.Background(), config)
		if err != nil {
			log.Fatal(fmt.Sprintf("Unable to connect to database: %v\n", err))
		}
		backend = phylumfs.New(conn)
	}

	defer func() {
		if conn != nil {
			log.Info("Closing datbase connection")
			conn.Close(context.Background())
		}
	}()

	rootCmd.AddCommand([]*cobra.Command{setupServeCommand(), setupAdminCommand()}...)
	rootCmd.Execute()
}

type phylumTracer struct {
}

func (p phylumTracer) TraceQueryStart(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryStartData) context.Context {
	log.Trace(fmt.Sprintf("%+v\n", data))
	return ctx
}

func (p phylumTracer) TraceQueryEnd(ctx context.Context, conn *pgx.Conn, data pgx.TraceQueryEndData) {
}
