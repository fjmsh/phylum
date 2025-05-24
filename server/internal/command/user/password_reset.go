package user

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/shroff/phylum/server/internal/mail"
	"github.com/spf13/cobra"
)

func setupPasswordResetCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "pwreset email",
		Short: "pwreset email",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]

			manager := user.ManagerFromContext(context.Background())
			if user, err := manager.UserByEmail(email); err != nil {
				fmt.Println("unable to find user" + email + ": " + err.Error())
				os.Exit(1)
			} else if token, err := manager.CreateResetToken(user); err != nil {
				fmt.Println("unable to create reset token: " + err.Error())
				os.Exit(1)
			} else if err := mail.SendPasswordResetEmail(user, token); err != nil {
				fmt.Println("unable to send email: " + err.Error())
				os.Exit(1)
			}
		},
	}
	return cmd
}
