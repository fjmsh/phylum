package fs

import (
	"context"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var fs core.FileSystem

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "fs",
		Short: "Filesystem Access",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			// Run root command persistent pre-run
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
			if err := core.Create(context.Background(), db.Default, storage.Default); err != nil {
				logrus.Fatal(err)
			}
		},
	}
	flags := cmd.PersistentFlags()
	flags.Bool("no-auto-migrate", false, "Do not automatically migrate database schema")
	viper.BindPFlag("no_auto_migrate", flags.Lookup("no-auto-migrate"))

	flags.StringP("default-storage-dir", "S", "storage/default", "Default Storage Directory")
	viper.BindPFlag("default_storage_dir", flags.Lookup("default-storage-dir"))

	flags.StringP("user", "u", "phylum", "Specify user for resource operations")

	cmd.AddCommand(
		setupLsCommand(),
		setupMkdirCommand(),
		setupRmCommand(),
		setupCpCommand(),
		setupChpermCommand(),
	)

	return cmd
}

func openFileSystemFromFlags(cmd *cobra.Command) {
	if value, err := cmd.Flags().GetString("user"); err != nil {
		logrus.Fatal(err)
	} else {
		if user, err := core.Default.UserByEmail(context.Background(), value); err != nil {
			logrus.Fatal(err)
		} else {
			fs = core.Default.OpenFileSystem(context.Background(), user)
		}
	}
}
