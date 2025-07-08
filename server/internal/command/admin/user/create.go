package user

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"os"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/spf13/cobra"
)

func setupInviteCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create <email>",
		Short: "Create User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]

			noCreateHome, _ := cmd.Flags().GetBool("no-create-home")
			noPassword, _ := cmd.Flags().GetBool("no-passwd")
			name, _ := cmd.Flags().GetString("name")
			reader := bufio.NewReader(os.Stdin)
			if name == "" {
				fmt.Print("Full Name: ")
				if val, err := reader.ReadString('\n'); err != nil {
					fmt.Println("failed to read stdin: " + err.Error())
					os.Exit(1)
				} else {
					name = strings.TrimSpace(val)
				}
			}

			password := ""
			if !noPassword {
				if p, err := readPassword(); err != nil {
					fmt.Println("failed to read password: " + err.Error())
					os.Exit(1)
				} else {
					password = p
				}
			}

			err := db.Get(context.Background()).RunInTx(func(db db.TxHandler) error {
				var user core.User
				if u, err := core.CreateUser(db, email, name, noCreateHome); err != nil {
					return err
				} else {
					user = u
				}

				if !noPassword {
					if err := auth.UpdateUserPassword(db, email, password); err != nil {
						return err
					}
				}

				if b, _ := cmd.Flags().GetBool("no-email"); !b {
					if err := mail.SendWelcomeEmail(user); err != nil {
						fmt.Println("Use --no-email if you want don't want to try sending the welcome email")
						return errors.New("unable to send welcome email: " + err.Error())
					}
				}
				return nil
			})
			if err != nil {
				fmt.Println("unable to create user: " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().StringP("name", "n", "", "Name")
	// TODO: #flags/#config
	cmd.Flags().StringP("user_basedir", "b", "", "Base directory for home")
	// TODO: #flags/#config
	cmd.Flags().BoolP("no-passwd", "P", false, "Do not create a password")
	cmd.Flags().BoolP("no-create-home", "M", false, "Do not make home directory")
	cmd.Flags().Bool("no-email", false, "Do not send email")

	return cmd
}
