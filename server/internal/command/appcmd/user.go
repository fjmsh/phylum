package appcmd

import (
	"context"
	"os"
	"strings"
	"syscall"

	"github.com/shroff/phylum/server/internal/app"
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
		setupUserListCommand(),
		setupUserLoginCommand(),
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

			if err := app.Default.CreateUser(context.Background(), username, displayName, password); err != nil {
				logrus.Fatal(err)
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
				logrus.Infof("%d: %s (%s)", user.ID(), user.Username(), user.DisplayName())
			}
		},
	}
}

func setupUserLoginCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "auth user",
		Short: "Authenticate user",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			username := strings.TrimSpace(args[0])

			os.Stdout.WriteString("Password: ")
			bytes, err := term.ReadPassword(syscall.Stdin)
			os.Stdout.WriteString("\n")
			if err != nil {
				logrus.Fatal(err)
			}
			password := string(bytes)

			accessToken, err := app.Default.CreateAccessToken(username, password)
			if err != nil {
				logrus.Fatal(err)
			}
			logrus.Info("Access Token: " + accessToken.ID)
			logrus.Info(" Valid Until: " + accessToken.Expires.Time.String())
		},
	}
}
