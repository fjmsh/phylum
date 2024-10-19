package appcmd

import (
	"context"
	"os"
	"syscall"

	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

func setupUserCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "user",
		Short: "User Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupUserAddCommand(),
		setupUserChrootCommand(),
		setupUserListCommand(),
	}...)
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

			if err := app.Default.CreateUser(context.Background(), email, displayName, password, nil); err != nil {
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
			if user, err := app.Default.UserByEmail(context.Background(), email); err != nil {
				logrus.Fatal(err)
			} else {
				if res, err := app.Default.Rootfs.ResourceByPathOrUuid(idOrPath); err != nil {
					logrus.Fatal(err)
				} else {
					app.Default.UpdateUserRoot(context.Background(), user, res.ID)
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
			users, err := app.Default.ListUsers(context.Background())
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
