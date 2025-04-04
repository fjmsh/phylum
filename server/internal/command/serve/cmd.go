package serve

import (
	"context"
	"time"

	"github.com/fvbock/endless"
	"github.com/shroff/phylum/server/internal/api/publink"
	apiv1 "github.com/shroff/phylum/server/internal/api/v1"
	"github.com/shroff/phylum/server/internal/api/webdav"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const trashRetainDuration = 30 * 24 * time.Hour

func SetupCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:     "serve",
		Short:   "Run the server",
		GroupID: "server",
		Run: func(cmd *cobra.Command, args []string) {
			config := viper.GetViper()
			engine := createEngine(config.GetBool("debug"), config.GetBool("log_body"), config.GetBool("cors_enabled"), config.GetStringSlice("cors_origins"))

			webdav.SetupHandler(engine.Group(config.GetString("webdav_prefix")))
			apiv1.Setup(engine.Group("/api/v1"))
			publink.Setup(engine.Group("/publink"))
			setupTrashCompactor()

			server := endless.NewServer(config.GetString("listen"), engine)
			server.BeforeBegin = func(addr string) {
				logrus.Info("Listening on " + addr)
			}

			if err := server.ListenAndServe(); err != nil {
				logrus.Fatal(err.Error())
			}
		},
	}
	flags := cmd.Flags()

	flags.Bool("auto-migrate", true, "Automatically migrate database schema")
	viper.BindPFlag("auto_migrate", flags.Lookup("auto-migrate"))

	flags.StringP("default-storage-dir", "S", "storage/default", "Default Storage Directory")
	viper.BindPFlag("default_storage_dir", flags.Lookup("default-storage-dir"))

	flags.StringP("listen", "l", ":1234", "Listen Addres")
	viper.BindPFlag("listen", flags.Lookup("listen"))

	flags.Bool("log-body", false, "Log Response Body (Must be used with --debug)")
	viper.BindPFlag("log_body", flags.Lookup("log-body"))

	flags.Bool("cors-enabled", false, "Enabled CORS")
	viper.BindPFlag("cors_enabled", flags.Lookup("cors-enabled"))

	flags.StringSlice("cors-origins", []string{"*"}, "CORS origins")
	viper.BindPFlag("cors_origins", flags.Lookup("cors-origins"))

	flags.String("webdav-prefix", "/webdav", "Listen Addres")
	viper.BindPFlag("webdav_prefix", flags.Lookup("webdav-prefix"))

	return cmd
}

func setupTrashCompactor() {
	ticker := time.NewTimer(24 * time.Hour)
	go func() {
		for {
			<-ticker.C
			fs.TrashCompact(context.Background(), trashRetainDuration)
		}
	}()
	fs.TrashCompact(context.Background(), trashRetainDuration)
}
