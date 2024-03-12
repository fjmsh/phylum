package command

import (
	"bufio"
	"context"
	"os"
	"strings"
	"syscall"

	"github.com/shroff/phylum/server/internal/cryptutil"
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
		setupUserLoginCommand(),
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

			hash, err := cryptutil.GenerateArgon2EncodedHash(password, cryptutil.DefaultArgon2Params())
			if err != nil {
				logrus.Fatal(err)
			}

			userManager.CreateUser(context.Background(), username, displayName, hash)
		},
	}
	return cmd
}

func setupUserLoginCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "auth",
		Short: "Authenticate user",
		Run: func(cmd *cobra.Command, args []string) {
			os.Stdout.WriteString("Username: ")
			reader := bufio.NewReader(os.Stdin)
			username, err := reader.ReadString('\n')
			if err != nil {
				logrus.Fatal(err)
			}
			username = strings.TrimSpace(username)

			user, err := userManager.FindUser(context.Background(), username)
			if err != nil {
				logrus.Fatal(err)
			}

			os.Stdout.WriteString("Password: ")
			bytes, err := term.ReadPassword(syscall.Stdin)
			os.Stdout.WriteString("\n")
			if err != nil {
				logrus.Fatal(err)
			}
			password := string(bytes)

			res, err := cryptutil.VerifyPassword(password, user.PasswordHash)
			if err != nil {
				logrus.Fatal(err)
			}
			if res {
				logrus.Info("Auth Succeeded")
			} else {
				logrus.Info("Auth Failed")
			}
		},
	}
	return cmd
}
