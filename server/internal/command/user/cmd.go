package user

import (
	"context"
	"os"
	"syscall"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"golang.org/x/term"
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

func setupUserAddCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "add email",
		Short: "Add User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]

			displayName, _ := cmd.Flags().GetString("name")
			if displayName == "" {
				displayName = email
			}

			password, _ := cmd.Flags().GetString("password")
			if password == "" {
				os.Stdout.WriteString("Password: ")
				bytes, err := term.ReadPassword(syscall.Stdin)
				os.Stdout.WriteString("\n")
				if err != nil {
					logrus.Fatal(err)
				}
				password = string(bytes)

				os.Stdout.WriteString("Confirm Password: ")
				bytes, err = term.ReadPassword(syscall.Stdin)
				os.Stdout.WriteString("\n")
				if err != nil {
					logrus.Fatal(err)
				}
				passwordConf := string(bytes)

				if password != passwordConf {
					logrus.Fatal("Password does not match confirmation")
				}
			}

			if err := common.App().CreateUser(context.Background(), email, displayName, password, nil); err != nil {
				logrus.Fatal(err)
			}
		},
	}
	cmd.Flags().StringP("name", "n", "", "Full Name")
	cmd.Flags().StringP("password", "p", "", "Password")
	return cmd
}

func setupUserChrootCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "chroot email uuid",
		Short: "Set User Root",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]
			idOrPath := args[1]
			if user, err := common.App().UserByEmail(context.Background(), email); err != nil {
				logrus.Fatal(err)
			} else {
				if res, err := common.App().Rootfs.ResourceByPathOrUuid(idOrPath); err != nil {
					logrus.Fatal(err)
				} else {
					common.App().UpdateUserRoot(context.Background(), user, res.ID)
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
			users, err := common.App().ListUsers(context.Background())
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
