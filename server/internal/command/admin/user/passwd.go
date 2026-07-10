package user

import (
	"context"
	"errors"
	"fmt"
	"os"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

func setupPasswdCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "passwd <email>",
		Short: "Change Password",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]
			password, err := cmd.Flags().GetString("password")
			if err != nil {
				fmt.Println("invalid password: " + err.Error())
				os.Exit(1)
			} else if password == "" {
				password, err = readPassword()
				if err != nil {
					fmt.Println("unable to read password from stdin: " + err.Error())
					os.Exit(1)
				}
			}

			if err := db.RunInTx(context.Background(), func(db db.TxHandler) error {
				return auth.Get().UpdateUserPassword(db, email, password)
			}); err != nil {
				fmt.Println("could not change password: " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().StringP("password", "p", "", "Password")
	return cmd
}

func readPassword() (string, error) {
	os.Stdout.WriteString("Password: ")
	bytes, err := term.ReadPassword(syscall.Stdin)
	os.Stdout.WriteString("\n")
	if err != nil {
		return "", err
	}
	password := string(bytes)

	os.Stdout.WriteString("Confirm Password: ")
	bytes, err = term.ReadPassword(syscall.Stdin)
	os.Stdout.WriteString("\n")
	if err != nil {
		return "", err
	}
	passwordConf := string(bytes)

	if password != passwordConf {
		return "", errors.New("password does not match confirmation")
	}
	return password, nil
}
