package user

import (
	"context"
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "user",
		Short: "User Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupListCommand(),
		setupCreateCommand(),
		setupModCommand(),
		setupPasswdCommand(),
		setupGrantCommand(),
		setupRevokeCommand(),
	}...)

	return cmd
}

func setupListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List Users",
		Run: func(cmd *cobra.Command, args []string) {
			users, err := core.ListUsers(db.Get(context.Background()), 0)
			if err != nil {
				fmt.Println("failed to list users: " + err.Error())
				os.Exit(1)
			}
			for _, user := range users {
				fmt.Printf("%24s :%.4x: %s\n", user.Email, user.Permissions, user.Name)
			}
		},
	}
}
