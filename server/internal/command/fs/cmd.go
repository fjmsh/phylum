package fs

import (
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		GroupID: "app",
		Use:     "fs",
		Short:   "Filesystem",
	}
	flags := cmd.PersistentFlags()
	flags.StringP("user", "u", "", "User")

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
		setupSearchCommand(),
	)

	return cmd
}
