package command

import (
	"github.com/spf13/cobra"
)

func setupAdminCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "admin",
		Short: "Server Administration",
	}
	cmd.AddCommand([]*cobra.Command{
		setupStorageCommand(),
		setupUserCommand(),
		setupSiloCommand(),
		setupSchemaCommand(),
	}...)

	return cmd
}
