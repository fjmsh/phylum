package user

import (
	"context"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "user",
		Short: "User Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupListCommand(),
		setupInviteCommand(),
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
				logrus.Fatal(err)
			}
			for _, user := range users {
				logrus.Infof("%24s :%.4x: %s", user.Email, user.Permissions, user.Name)
			}
		},
	}
}
