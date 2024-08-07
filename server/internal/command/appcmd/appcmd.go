package appcmd

import (
	"context"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand(db **db.DbHandler, debug bool) *cobra.Command {
	var cs storage.Storage
	cmd := &cobra.Command{
		Use:   "app",
		Short: "Server Administration",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			c := cmd.Parent()
			for ; c.Parent() != nil; c = c.Parent() {
			}
			c.PersistentPreRun(cmd, args)
			if err := (*db).CheckVersion(context.Background(), !viper.GetBool("no_auto_migrate")); err != nil {
				logrus.Fatal(err)
			}

			var err error
			if cs, err = storage.Open(*db, context.Background(), viper.GetString("content-dir")); err != nil {
				logrus.Fatal(err)
			} else {
				if err := core.Create(context.Background(), *db, cs, debug); err != nil {
					logrus.Fatal(err)
				}
			}
		},
	}
	flags := cmd.Flags()
	flags.Bool("no-auto-migrate", false, "Do not automatically migrate database schema")
	viper.BindPFlag("no_auto_migrate", flags.Lookup("auto-migrate"))

	flags.StringP("content-dir", "C", "content", "Content Directory")
	viper.BindPFlag("content_dir", flags.Lookup("content-dir"))

	cmd.AddCommand([]*cobra.Command{
		setupServeCommand(),
		setupUserCommand(),
		setupResourceCommand(),
		setupStorageCommand(cs),
	}...)

	return cmd
}
