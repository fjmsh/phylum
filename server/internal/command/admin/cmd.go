package admin

import (
	"codeberg.org/shroff/phylum/server/internal/command/admin/jobs"
	"codeberg.org/shroff/phylum/server/internal/command/admin/schema"
	"codeberg.org/shroff/phylum/server/internal/command/admin/storage"
	"codeberg.org/shroff/phylum/server/internal/command/admin/user"
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
		jobs.SetupCommand(),
	}...)

	return cmd
}
