package appcmd

import (
	"context"
	"os"
	"syscall"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
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
		Use:   "add username",
		Short: "Add User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			username := args[0]

			displayName, _ := cmd.Flags().GetString("name")
			if displayName == "" {
				displayName = username
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

			if err := core.Default.CreateUser(context.Background(), username, displayName, password, nil); err != nil {
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
		Use:   "chroot username uuid",
		Short: "Set User Root",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			username := args[0]
			idOrPath := args[1]
			if user, err := core.Default.UserByUsername(context.Background(), username); err != nil {
				logrus.Fatal(err)
			} else {
				var res core.Resource
				if id, err := uuid.Parse(idOrPath); err == nil {
					if res, err = core.Default.Rootfs.ResourceByID(id); err != nil {
						logrus.Fatal(err)
					}
				} else {
					if res, err = core.Default.Rootfs.ResourceByPath(idOrPath); err != nil {
						logrus.Fatal(err)
					}
				}
				core.Default.UpdateUserRoot(context.Background(), user, res.ID())
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
			users, err := core.Default.ListUsers(context.Background())
			if err != nil {
				logrus.Fatal(err)
			}
			for _, user := range users {
				logrus.Infof(" %3.3d: %s (%s)", user.ID(), user.Username(), user.DisplayName())
				logrus.Infof("Root: %s", user.Root())
				logrus.Infof("Home: %s", user.Home())
			}
		},
	}
}
