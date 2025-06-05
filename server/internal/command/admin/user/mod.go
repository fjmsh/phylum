package user

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core"
	core1 "github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

func setupModCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "mod email",
		Short: "Modify",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			email := args[0]
			u, err := core1.UserManagerFromContext(context.Background()).UserByEmail(email)
			if err != nil {
				fmt.Println("could not update user '" + email + "': " + err.Error())
				os.Exit(1)
			}

			name, _ := cmd.Flags().GetString("name")

			f := core.OpenOmniscient(db.Get(context.Background()))
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
				m := core1.UserManagerFromDB(db)
				if name != "" {
					if err := m.UpdateUserName(u, name); err != nil {
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
	cmd.Flags().StringP("name", "n", "", "Name")
	cmd.Flags().StringP("home", "d", "", "Home Directory")
	return cmd
}
