package common

import (
	"context"
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

var u *core.User
var f core.FileSystem

func User(cmd *cobra.Command) *core.User {
	if u == nil {
		if value, err := cmd.Flags().GetString("user-email"); err != nil {
			fmt.Println("could not read user: " + err.Error())
			os.Exit(1)
		} else if value == "" {
			u = nil
		} else {
			if user, err := core.UserManagerFromContext(context.Background()).UserByEmail(value); err != nil {
				fmt.Println("could not find user '" + value + "': " + err.Error())
				os.Exit(1)
			} else {
				u = &user
			}
		}
	}
	return u
}

func UserFileSystem(cmd *cobra.Command) core.FileSystem {
	if f == nil {
		user := User(cmd)
		if user == nil {
			f = core.OpenOmniscient(db.Get(context.Background()))
		} else {
			f = user.OpenFileSystem(context.Background())
		}
	}
	return f
}
