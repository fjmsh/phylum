package user

import (
	"codeberg.org/shroff/phylum/server/internal/command/user/bookmarks"
	"codeberg.org/shroff/phylum/server/internal/command/user/keys"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "user",
		Short: "User Management",
	}
	cmd.PersistentFlags().StringP("user-email", "u", "", "User")
	cmd.AddCommand([]*cobra.Command{
		keys.SetupCommand(),
		bookmarks.SetupCommand(),
	}...)

	return cmd
}
