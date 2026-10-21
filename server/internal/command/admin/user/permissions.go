package user

import (
	"context"
	"fmt"
	"os"
	"slices"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

func setupGrantCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "grant <email> <permissions>",
		Short: "Grant Permissions",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			d := db.Get(context.Background())
			u, err := core.UserByEmail(d, args[0])
			if err != nil {
				fmt.Println("unable to find user :" + err.Error())
				os.Exit(1)
			}
			p := append(u.Privileges, core.UserPrivilege(strings.TrimSpace(args[1])))

			if err := d.RunInTx(func(db db.TxHandler) error {
				return core.SetUserPrivileges(db, u.ID, p)
			}); err != nil {
				fmt.Println("failed to grant permission: " + err.Error())
				os.Exit(1)
			}
		},
	}
}

func setupRevokeCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "revoke <email> <permissions>",
		Short: "Revoke Permissions",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			d := db.Get(context.Background())
			u, err := core.UserByEmail(d, args[0])
			if err != nil {
				fmt.Println("unable to find user :" + err.Error())
				os.Exit(1)
			}

			input := strings.TrimSpace(args[1])
			p := slices.DeleteFunc(u.Privileges, func(p core.UserPrivilege) bool {
				ps := string(p)
				return ps == input || strings.HasPrefix(ps, input+":") || input == "*"
			})

			if err := d.RunInTx(func(db db.TxHandler) error {
				// TODO: Accept email directly instead of having to separately fetch the user
				return core.SetUserPrivileges(db, u.ID, p)
			}); err != nil {
				fmt.Println("failed to revoke permission: " + err.Error())
				os.Exit(1)
			}
		},
	}
}
