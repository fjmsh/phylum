package admin

import (
	"github.com/shroff/phylum/server/internal/command/admin/schema"
	"github.com/shroff/phylum/server/internal/command/admin/storage"
	"github.com/shroff/phylum/server/internal/command/admin/user"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "admin",
		Short: "Admin Commands",
	}
	cmd.AddCommand([]*cobra.Command{
		user.SetupCommand(),
		schema.SetupCommand(),
		storage.SetupCommand(),
	}...)

	return cmd
}
