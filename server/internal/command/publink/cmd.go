package publink

import (
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "publink",
		Short:   "Publink Management",
		GroupID: "app",
	}
	flags := cmd.PersistentFlags()
	flags.StringP("user", "u", "", "User")

	cmd.AddCommand(
		setupCreateCommand(),
	)

	return cmd
}
