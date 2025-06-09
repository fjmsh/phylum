package user

import (
	"context"
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/spf13/cobra"
)

func setupPwresetResetCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "pwreset <email>",
		Short: "Send password reset email",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]

			if user, token, err := auth.CreateResetToken(context.Background(), email); err != nil {
				fmt.Println("unable to create reset token: " + err.Error())
				os.Exit(1)
			} else {
				if b, _ := cmd.Flags().GetBool("no-email"); b {
					fmt.Println("Created password reset token: " + token)
				} else {
					if err := mail.SendPasswordResetEmail(user, token); err != nil {
						fmt.Println("unable to send email: " + err.Error())
						fmt.Println("Use --no-email print the reset token instead instad of sending it by email")
						os.Exit(1)
					}
				}
			}
		},
	}
	cmd.Flags().Bool("no-email", false, "Do not send email")
	return cmd
}
