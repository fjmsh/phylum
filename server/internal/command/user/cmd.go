package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		GroupID: "admin",
		Use:     "user",
		Short:   "User Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupUserAddCommand(),
		setupUserModCommand(),
		setupUserListCommand(),
		setupUserPasswdCommand(),
		setupBookmarksCommand(),
	}...)

	flags := cmd.PersistentFlags()
	flags.Bool("auto-migrate", true, "Automatically migrate database schema")
	viper.BindPFlag("auto_migrate", flags.Lookup("auto-migrate"))

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
				logrus.Infof("%24s : %s", user.Username, user.DisplayName)
			}
		},
	}
}
