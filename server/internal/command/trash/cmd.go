package trash

import (
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		GroupID: "app",
		Use:     "trash",
		Short:   "Trash",
	}
	flags := cmd.PersistentFlags()
	flags.StringP("user", "u", "phylum", "User")

	cmd.AddCommand(
		setupDeleteCommand(),
		setupEmptyCommand(),
		setupListCommand(),
		setupRestoreCommand(),
		setupSummaryCommand(),
	)

	return cmd
}
