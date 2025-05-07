package user

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

func setupUserModCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "mod username",
		Short: "Add User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			username := args[0]
			u, err := user.ManagerFromContext(context.Background()).UserByEmail(username)
			if err != nil {
				fmt.Println("could not update user '" + username + "': " + err.Error())
				os.Exit(1)
			}

			displayName, _ := cmd.Flags().GetString("name")

			rootFS := common.RootFileSystem()
			var homeID pgtype.UUID
			if pathOrUUID, err := cmd.Flags().GetString("home"); err != nil {
				fmt.Println("invalid value for flag 'home': " + err.Error())
				os.Exit(1)
			} else if pathOrUUID != "" {
				if r, err := rootFS.ResourceByPathOrUUID(pathOrUUID); err != nil {
					fmt.Println("invalid value for flag 'home': " + err.Error())
					os.Exit(1)
				} else {
					homeID = pgtype.UUID{
						Bytes: r.ID(),
						Valid: true,
					}
				}
			}

			err = db.Get(context.Background()).RunInTx(func(db db.Handler) error {
				m := user.ManagerFromDB(db)
				if displayName != "" {
					if err := m.UpdateUserDisplayName(u, displayName); err != nil {
						return err
					}
				}
				if homeID.Valid {
					if err := m.UpdateUserHome(u, homeID); err != nil {
						return err
					}
				}
				return nil
			})
			if err != nil {
				fmt.Println("could not update user '" + username + "': " + err.Error())
				os.Exit(3)
			}
		},
	}
	cmd.Flags().StringP("name", "n", "", "Display Name")
	cmd.Flags().StringP("home", "d", "", "Home Directory")
	return cmd
}
