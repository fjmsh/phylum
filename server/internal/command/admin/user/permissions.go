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
			db := db.Get(context.Background())
			u, err := core.UserByEmail(db, args[0])
			if err != nil {
				fmt.Println("unable to find user :" + err.Error())
				os.Exit(1)
			}
			var p core.UserPermissions
			permString := strings.TrimSpace(args[1])
			if strings.HasPrefix(permString, "0x") {
				var perm int64
				perm, err = strconv.ParseInt(permString[2:], 16, 32)
				p = int32(perm)
			} else {
				var perm int64
				perm, err = strconv.ParseInt(permString, 10, 32)
				p = int32(perm)
			}
			if err != nil {
				fmt.Println("unable to parse permissions " + permString)
				os.Exit(1)
			}

			core.GrantUserPermissions(db, u, p)
			if err != nil {
				fmt.Println("unable to update permissions:" + err.Error())
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
			db := db.Get(context.Background())
			u, err := core.UserByEmail(db, args[0])
			if err != nil {
				fmt.Println("unable to find user :" + err.Error())
				os.Exit(1)
			}
			var p core.UserPermissions
			permString := strings.TrimSpace(args[1])
			if strings.HasPrefix(permString, "0x") {
				var perm int64
				perm, err = strconv.ParseInt(permString[2:], 16, 32)
				p = int32(perm)
			} else {
				var perm int64
				perm, err = strconv.ParseInt(permString, 10, 32)
				p = int32(perm)
			}
			if err != nil {
				fmt.Println("unable to parse permissions " + permString)
				os.Exit(1)
			}

			core.RevokeUserPermissions(db, u, p)
			if err != nil {
				fmt.Println("unable to update permissions:" + err.Error())
				os.Exit(1)
			}
		},
	}
}
