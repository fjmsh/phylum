package user

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/shroff/phylum/server/internal/mail"
	"github.com/spf13/cobra"
)

func setupInviteCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "invite email",
		Short: "Invite User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]

			displayName := ""
			if n, err := cmd.Flags().GetString("name"); err != nil {
				fmt.Println("invalid value for flag 'name': " + err.Error())
				os.Exit(1)
			} else if n != "" {
				displayName = n
			}

			noCreateHome, _ := cmd.Flags().GetBool("no-create-home")
			homePath := ""
			if !noCreateHome {
				basePath, _ := cmd.Flags().GetString("base-dir")
				homePath = strings.TrimRight(basePath, "/") + "/" + email
			}

			var u user.User
			err := db.Get(context.Background()).RunInTx(func(db db.Handler) error {
				userManager := user.ManagerFromDB(db)
				if user, err := userManager.CreateUser(email, displayName, homePath); err != nil {
					return err
				} else {
					u = user
				}

				if b, _ := cmd.Flags().GetBool("no-email"); !b {
					if err := mail.SendWelcomeEmail(u); err != nil {
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
	cmd.Flags().StringP("name", "n", "", "Full Name")
	cmd.Flags().StringP("base-dir", "b", "/home", "Base directory for home")
	cmd.Flags().BoolP("no-create-home", "M", false, "Do not make home directory")
	cmd.Flags().Bool("no-email", false, "Do not send email")
	return cmd
}
