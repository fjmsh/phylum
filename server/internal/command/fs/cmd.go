package fs

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

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
				fmt.Println("could not migrate database schema: " + err.Error())
				os.Exit(1)
			}
			if err := storage.Create(context.Background(), db.Default, viper.GetString("default_storage_dir")); err != nil {
				fmt.Println("could not open storage: " + err.Error())
				os.Exit(1)
			}
			if err := app.Create(context.Background(), db.Default, storage.Default); err != nil {
				fmt.Println("could not initialized app: " + err.Error())
				os.Exit(1)
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
