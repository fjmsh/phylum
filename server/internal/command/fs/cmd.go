package fs

import (
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "fs",
		Short:   "Filesystem Access",
		GroupID: "app",
	}
	flags := cmd.PersistentFlags()
	flags.Bool("auto-migrate", true, "Automatically migrate database schema")
	viper.BindPFlag("auto_migrate", flags.Lookup("auto-migrate"))

	flags.StringP("default-storage-dir", "S", "storage/default", "Default Storage Directory")
	viper.BindPFlag("default_storage_dir", flags.Lookup("default-storage-dir"))

	flags.StringP("user", "u", "phylum", "User")

	cmd.AddCommand(
		setupCatCommand(),
		setupChpermCommand(),
		setupCpCommand(),
		setupImportCommand(),
		setupLsCommand(),
		setupMkdirCommand(),
		setupMvCommand(),
		setupPublinksCommand(),
		setupRmCommand(),
	)

	return cmd
}
