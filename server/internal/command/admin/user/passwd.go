package user

import (
	"context"
	"fmt"
	"os"
	"syscall"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

func setupPasswdCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "passwd email",
		Short: "Change Password",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]
			u, err := core.UserManagerFromContext(context.Background()).UserByEmail(email)
			if err != nil {
				fmt.Println("unable to change password: " + err.Error())
				os.Exit(1)
			}

			password, err := cmd.Flags().GetString("password")
			if err != nil {
				fmt.Println("invalid password: " + err.Error())
				os.Exit(1)
			} else if password == "" {
				os.Stdout.WriteString("Password: ")
				bytes, err := term.ReadPassword(syscall.Stdin)
				os.Stdout.WriteString("\n")
				if err != nil {
					fmt.Println("unable to read password: " + err.Error())
					os.Exit(1)
				}
				password = string(bytes)

				os.Stdout.WriteString("Confirm Password: ")
				bytes, err = term.ReadPassword(syscall.Stdin)
				os.Stdout.WriteString("\n")
				if err != nil {
					fmt.Println("unable to read password: " + err.Error())
					os.Exit(1)
				}
				passwordConf := string(bytes)

				if password != passwordConf {
					fmt.Println("password does not match confirmation")
					os.Exit(1)
				}
			}

			err = core.UserManagerFromContext(context.Background()).UpdateUserPassword(u, password)
			if err != nil {
				fmt.Println("could not add user: " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().StringP("password", "p", "", "Password")
	return cmd
}
