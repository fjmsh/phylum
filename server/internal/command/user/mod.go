package user

import (
	"context"
	"fmt"
	"os"

	"github.com/google/uuid"
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
			u, err := user.CreateManager(context.Background()).UserByEmail(username)
			if err != nil {
				fmt.Println("could not update user '" + username + "': " + err.Error())
				os.Exit(1)
			}

			displayName, _ := cmd.Flags().GetString("name")

			rootFS := common.RootFileSystem()
			chrootID := uuid.Nil
			if rootPathOrUUID, err := cmd.Flags().GetString("chroot"); err != nil {
				fmt.Println("invalid value for flag 'chroot': " + err.Error())
				os.Exit(1)
			} else if rootPathOrUUID != "" {
				if r, err := rootFS.ResourceByPathOrUUID(rootPathOrUUID); err != nil {
					fmt.Println("invalid value for flag 'chroot': " + err.Error())
					os.Exit(1)
				} else {
					chrootID = r.ID()
				}
			}

			homeID := uuid.Nil
			if pathOrUUID, err := cmd.Flags().GetString("home"); err != nil {
				fmt.Println("invalid value for flag 'home': " + err.Error())
				os.Exit(1)
			} else if pathOrUUID != "" {
				if r, err := rootFS.ResourceByPathOrUUID(pathOrUUID); err != nil {
					fmt.Println("invalid value for flag 'home': " + err.Error())
					os.Exit(1)
				} else {
					homeID = r.ID()
				}
			}

			ctx := context.Background()
			err = db.Get().RunInTx(ctx, func(db *db.Handler) error {
				m := user.CreateManager(ctx).WithDb(db)
				if displayName != "" {
					if err := m.UpdateUserDisplayName(u, displayName); err != nil {
						return err
					}
				}
				if chrootID != uuid.Nil {
					if err := m.UpdateUserRoot(u, chrootID); err != nil {
						return err
					}
				}
				if homeID != uuid.Nil {
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
	cmd.Flags().StringP("name", "n", "", "Full Name")
	cmd.Flags().StringP("chroot", "R", "", "Chroot")
	cmd.Flags().StringP("home", "d", "", "Home directory")
	return cmd
}
