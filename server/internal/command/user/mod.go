package user

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

func setupUserModCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "mod email",
		Short: "Add User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]
			u, err := user.ManagerFromContext(context.Background()).UserByEmail(email)
			if err != nil {
				fmt.Println("could not update user '" + email + "': " + err.Error())
				os.Exit(1)
			}

			displayName, _ := cmd.Flags().GetString("name")

			f := fs.OpenOmniscient(db.Get(context.Background()))
			var homeID pgtype.UUID
			path, _ := cmd.Flags().GetString("home")
			if path != "" {
				if r, err := f.ResourceByPathWithRoot(path); err != nil {
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
				fmt.Println("could not update user '" + email + "': " + err.Error())
				os.Exit(3)
			}
		},
	}
	cmd.Flags().StringP("name", "n", "", "Display Name")
	cmd.Flags().StringP("home", "d", "", "Home Directory")
	return cmd
}
