package appcmd

import (
	"github.com/shroff/phylum/server/internal/app"
	"github.com/shroff/phylum/server/internal/command/appcmd/admincmd"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand(db **db.DbHandler, debug bool) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "app",
		Short: "Server Administration",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			if err := (*db).CheckVersion(!viper.GetBool("no_auto_migrate")); err != nil {
				logrus.Fatal(err)
			}
			if err := app.Initialize(*db, debug); err != nil {
				logrus.Fatal(err)
			}
		},
	}
	flags := cmd.Flags()
	flags.Bool("no-auto-migrate", false, "Do not automatically migrate database schema")
	viper.BindPFlag("no_auto_migrate", flags.Lookup("auto-migrate"))

	cmd.AddCommand([]*cobra.Command{
		admincmd.SetupCommand(),
		setupServeCommand(),
	}...)

	return cmd
}
