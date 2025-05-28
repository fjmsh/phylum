package user

import (
	"github.com/shroff/phylum/server/internal/command/user/bookmarks"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "user",
		Short: "User Management",
	}
	cmd.PersistentFlags().StringP("user-email", "u", "", "User")
	cmd.AddCommand([]*cobra.Command{
		bookmarks.SetupCommand(),
	}...)

	return cmd
}
