package user

import (
	"context"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "user",
		Short: "User Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupUserAddCommand(),
		setupUserChrootCommand(),
		setupUserListCommand(),
	}...)

	flags := cmd.PersistentFlags()
	flags.Bool("auto-migrate", true, "Automatically migrate database schema")
	viper.BindPFlag("auto_migrate", flags.Lookup("auto-migrate"))

	return cmd
}

func setupUserChrootCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "chroot <username> [ <path> | <uuid> ]",
		Short: "Set User Root",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]
			idOrPath := args[1]
			userManager := user.CreateManager(context.Background())
			if user, err := userManager.UserByEmail(email); err != nil {
				logrus.Fatal(err)
			} else {
				if res, err := common.RootFileSystem().ResourceByPathOrUUID(idOrPath); err != nil {
					logrus.Fatal(err)
				} else {
					userManager.UpdateUserRoot(user, res.ID)
				}
			}
		},
	}
	cmd.Flags().StringP("name", "n", "", "Full Name")
	cmd.Flags().StringP("password", "p", "", "Password")
	return cmd
}

func setupUserListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List Users",
		Run: func(cmd *cobra.Command, args []string) {
			users, err := user.CreateManager(context.Background()).AllUsers()
			if err != nil {
				logrus.Fatal(err)
			}
			for _, user := range users {
				logrus.Infof("%s", user.Username)
				logrus.Infof("    Name: %s", user.DisplayName)
				logrus.Infof("    Root: %s", user.Root)
				logrus.Infof("    Home: %s", user.Home)
			}
		},
	}
}
