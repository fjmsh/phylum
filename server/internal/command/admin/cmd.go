package admin

import (
	"codeberg.org/shroff/phylum/server/internal/command/admin/config"
	"codeberg.org/shroff/phylum/server/internal/command/admin/jobs"
	"codeberg.org/shroff/phylum/server/internal/command/admin/migrate"
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
		config.SetupCommand(),
		user.SetupCommand(),
		schema.SetupCommand(),
		storage.SetupCommand(),
		jobs.SetupCommand(),
		migrate.SetupCommand(),
	}...)

	return cmd
}
