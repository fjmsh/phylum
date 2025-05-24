package user

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
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

			f := common.RootFileSystem()
			noCreateHome, _ := cmd.Flags().GetBool("no-create-home")
			homePath := ""
			if !noCreateHome {
				basePath, _ := cmd.Flags().GetString("base-dir")
				homePath = strings.TrimRight(basePath, "/") + "/" + email
			}

			var u user.User
			err := db.Get(context.Background()).RunInTx(func(db db.Handler) error {
				userManager := user.ManagerFromDB(db)
				var home fs.Resource
				if homePath != "" {
					f = f.WithDb(db)
					var err error
					home, err = f.CreateResourceByPath(homePath, uuid.Nil, true, true, fs.ResourceBindConflictResolutionEnsure)
					if err != nil {
						return err
					}
				}

				var homeID pgtype.UUID
				if home.ID() != uuid.Nil {
					homeID = pgtype.UUID{
						Bytes: home.ID(),
						Valid: true,
					}
				}
				if user, err := userManager.CreateUser(email, displayName, homeID); err != nil {
					return err
				} else {
					u = user
				}

				if homeID.Valid {
					if _, err := home.UpdatePermissions(u.ID, fs.PermissionRead|fs.PermissionWrite|fs.PermissionShare); err != nil {
						return err
					}
				}

				return nil
			})
			if err != nil {
				fmt.Println("unable to create user: " + err.Error())
				os.Exit(1)
			}
			fmt.Println("User created")
			if sendInviteEmail(u) != nil {
				fmt.Println("unable to send email: " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().StringP("name", "n", "", "Full Name")
	cmd.Flags().StringP("base-dir", "b", "/home", "Base directory for home")
	cmd.Flags().BoolP("no-create-home", "M", false, "Do not make home directory")
	return cmd
}

func setupResetPasswordCommand() *cobra.Command {
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
			} else if err := sendResetToken(user, token); err != nil {
				fmt.Println("unable to send email: " + err.Error())
				os.Exit(1)
			}
		},
	}
	return cmd
}

func sendInviteEmail(user user.User) error {
	return mail.Send(mail.Message{
		ToName:  user.DisplayName,
		ToEmail: user.Email,
		Subject: "An account has been created for you",
		Body:    "An account has been created for you at",
	})
}

func sendResetToken(user user.User, token string) error {
	return mail.Send(mail.Message{
		ToName:  user.DisplayName,
		ToEmail: user.Email,
		Subject: "Reset your password",
		Body:    "Token: " + token,
	})
}
