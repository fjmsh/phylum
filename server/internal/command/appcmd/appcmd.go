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

func SetupCommand(debug bool) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "app",
		Short: "Server Administration",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			c := cmd.Parent()
			for ; c.Parent() != nil; c = c.Parent() {
			}
			c.PersistentPreRun(cmd, args)
			if err := db.Default.CheckVersion(context.Background(), !viper.GetBool("no_auto_migrate")); err != nil {
				logrus.Fatal(err)
			}

			if err := storage.Create(context.Background(), db.Default, viper.GetString("default_storage_dir")); err != nil {
				logrus.Fatal(err)
			}
			if err := core.Create(context.Background(), db.Default, storage.Default, debug); err != nil {
				logrus.Fatal(err)
			}
		},
	}
	flags := cmd.Flags()
	flags.Bool("no-auto-migrate", false, "Do not automatically migrate database schema")
	viper.BindPFlag("no_auto_migrate", flags.Lookup("no-auto-migrate"))

	flags.StringP("default-storage-dir", "S", "storage/default", "Default Storage Directory")
	viper.BindPFlag("default_storage_dir", flags.Lookup("default-storage-dir"))

	cmd.AddCommand([]*cobra.Command{
		setupServeCommand(),
		setupUserCommand(),
		setupResourceCommand(),
		setupStorageCommand(),
	}...)

	return cmd
}
