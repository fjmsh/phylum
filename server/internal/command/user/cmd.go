package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		GroupID: "admin",
		Use:     "user",
		Short:   "User Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupInviteCommand(),
		setupPasswordResetCommand(),
		setupUserModCommand(),
		setupUserListCommand(),
		setupUserPasswdCommand(),
		setupBookmarksCommand(),
	}...)

	return cmd
}

func setupUserListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List Users",
		Run: func(cmd *cobra.Command, args []string) {
			users, err := user.ManagerFromContext(context.Background()).ListUsers(nil)
			if err != nil {
				logrus.Fatal(err)
			}
			for _, user := range users {
				logrus.Infof("%24s : %s", user.Email, user.DisplayName)
			}
		},
	}
}
