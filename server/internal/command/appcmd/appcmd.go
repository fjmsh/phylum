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
			c := cmd.Parent()
			for ; c.Parent() != nil; c = c.Parent() {
			}
			c.PersistentPreRun(cmd, args)
			if err := (*db).CheckVersion(!viper.GetBool("no_auto_migrate")); err != nil {
				logrus.Fatal(err)
			}
			if err := app.Initialize(*db, viper.GetString("content-dir"), debug); err != nil {
				logrus.Fatal(err)
			}
		},
	}
	flags := cmd.Flags()
	flags.Bool("no-auto-migrate", false, "Do not automatically migrate database schema")
	viper.BindPFlag("no_auto_migrate", flags.Lookup("auto-migrate"))

	flags.StringP("content-dir", "C", "content", "Content Directory")
	viper.BindPFlag("content_dir", flags.Lookup("content-dir"))

	cmd.AddCommand([]*cobra.Command{
		admincmd.SetupCommand(),
		setupServeCommand(),
		setupResourceCommand(),
	}...)

	return cmd
}
