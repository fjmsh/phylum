package trash

import (
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "trash",
		Short: "Trash",
	}

	cmd.AddCommand(
		setupDeleteCommand(),
		setupEmptyCommand(),
		setupListCommand(),
		setupRestoreCommand(),
		setupSummaryCommand(),
	)

	return cmd
}
