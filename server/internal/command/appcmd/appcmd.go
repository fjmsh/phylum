package appcmd

import (
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "app",
		Short: "Server Administration",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			c := cmd.Parent()
			for ; c.Parent() != nil; c = c.Parent() {
			}
			c.PersistentPreRun(cmd, args)

			if viper.GetBool("no_auto_migrate") {
				common.MustInitializeDB(false)
			}
			common.MustInitializeApp()
		},
	}
	flags := cmd.PersistentFlags()
	flags.Bool("no-auto-migrate", false, "Do not automatically migrate database schema")
	viper.BindPFlag("no_auto_migrate", flags.Lookup("no-auto-migrate"))

	flags.StringP("default-storage-dir", "S", "storage/default", "Default Storage Directory")
	viper.BindPFlag("default_storage_dir", flags.Lookup("default-storage-dir"))

	cmd.AddCommand([]*cobra.Command{
		setupServeCommand(),
		setupUserCommand(),
		setupStorageCommand(),
	}...)

	return cmd
}
