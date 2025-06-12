package user

import (
	"context"
	"errors"
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/spf13/cobra"
)

func setupInviteCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "invite email",
		Short: "Invite User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]

			name, _ := cmd.Flags().GetString("name")
			noCreateHome, _ := cmd.Flags().GetBool("no-create-home")

			err := db.Get(context.Background()).RunInTx(func(db db.TxHandler) error {
				var user core.User
				if u, err := core.CreateUser(db, email, name, noCreateHome); err != nil {
					return err
				} else {
					user = u
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
	cmd.Flags().BoolP("no-create-home", "M", false, "Do not make home directory")
	cmd.Flags().Bool("no-email", false, "Do not send email")
	return cmd
}
