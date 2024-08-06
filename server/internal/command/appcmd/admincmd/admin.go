package admincmd

import (
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/spf13/cobra"
)

func SetupCommand(cs storage.Storage) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "admin",
		Short: "Server Administration",
	}
	cmd.AddCommand([]*cobra.Command{
		setupStorageCommand(cs),
		setupUserCommand(),
	}...)

	return cmd
}
