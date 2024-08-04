package admincmd

import (
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "admin",
		Short: "Server Administration",
	}
	cmd.AddCommand([]*cobra.Command{
		setupStorageCommand(),
		setupUserCommand(),
		setupSiloCommand(),
	}...)

	return cmd
}
