package user

import (
	"context"
	"fmt"
	"os"
	"strconv"
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
			var p core.UserPermissions
			permString := strings.TrimSpace(args[1])
			if strings.HasPrefix(permString, "0x") {
				var perm int64
				perm, err = strconv.ParseInt(permString[2:], 16, 32)
				p = core.UserPermissions(perm)
			} else {
				var perm int64
				perm, err = strconv.ParseInt(permString, 10, 32)
				p = core.UserPermissions(perm)
			}
			if err != nil {
				fmt.Println("failed to parse permission: " + err.Error())
				os.Exit(1)
			}

			if err := d.RunInTx(func(db db.TxHandler) error {
				return core.GrantUserPermissions(db, u.ID, p)
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
			var p core.UserPermissions
			permString := strings.TrimSpace(args[1])
			if strings.HasPrefix(permString, "0x") {
				var perm int64
				perm, err = strconv.ParseInt(permString[2:], 16, 32)
				p = core.UserPermissions(perm)
			} else {
				var perm int64
				perm, err = strconv.ParseInt(permString, 10, 32)
				p = core.UserPermissions(perm)
			}
			if err != nil {
				fmt.Println("failed to parse permission: " + err.Error())
				os.Exit(1)
			}

			if err := d.RunInTx(func(db db.TxHandler) error {
				// TODO: Accept email directly instead of having to separately fetch the user
				return core.RevokeUserPermissions(db, u.ID, p)
			}); err != nil {
				fmt.Println("failed to revoke permission: " + err.Error())
				os.Exit(1)
			}
		},
	}
}
