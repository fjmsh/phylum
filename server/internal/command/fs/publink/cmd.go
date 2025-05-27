package publink

import (
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "publink",
		Short: "Publink Management",
	}

	cmd.AddCommand(
		setupCreateCommand(),
		setupListCommand(),
	)

	return cmd
}
