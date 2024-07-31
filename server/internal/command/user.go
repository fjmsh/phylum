package command

import (
	"bufio"
	"context"
	"fmt"
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
		setupUserCreateCommand(),
		setupUserListCommand(),
		setupUserLoginCommand(),
		setupUserVerifyTokenCommand(),
	}...)
	return cmd
}

func setupUserCreateCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create User",
		Run: func(cmd *cobra.Command, args []string) {
			os.Stdout.WriteString("Full Name: ")
			reader := bufio.NewReader(os.Stdin)
			displayName, err := reader.ReadString('\n')
			if err != nil {
				logrus.Fatal(err)
			}
			displayName = strings.TrimSpace(displayName)

			os.Stdout.WriteString("Username: ")
			username, err := reader.ReadString('\n')
			if err != nil {
				logrus.Fatal(err)
			}
			username = strings.TrimSpace(username)

			os.Stdout.WriteString("Password: ")
			bytes, err := term.ReadPassword(syscall.Stdin)
			os.Stdout.WriteString("\n")
			if err != nil {
				logrus.Fatal(err)
			}
			password := string(bytes)

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

			if err := app.Default.CreateUser(context.Background(), username, displayName, password); err != nil {
				logrus.Fatal(err)
			}
		},
	}
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
				logrus.Infof("%16s: %s", user.Username, user.DisplayName)
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

func setupUserVerifyTokenCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "verify-token token",
		Short: "Verify access token",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			token := strings.TrimSpace(args[0])

			session, err := app.Default.VerifyAccessToken(token)
			if err != nil {
				logrus.Fatal(err)
			}
			logrus.Info(fmt.Sprintf("%+v\n", session))
		},
	}
}
