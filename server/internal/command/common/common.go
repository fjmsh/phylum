package common

import (
	"context"
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

var u *core.User
var f *core.FileSystem

func User(cmd *cobra.Command) *core.User {
	if u == nil {
		if value, err := cmd.Flags().GetString("user-email"); err != nil {
			fmt.Println("could not read user: " + err.Error())
			os.Exit(1)
		} else if value == "" {
			u = nil
		} else {
			if user, err := core.UserByEmail(db.Get(context.Background()), value); err != nil {
				fmt.Println("could not find user '" + value + "': " + err.Error())
				os.Exit(1)
			} else {
				u = &user
			}
		}
	}
	return u
}

func UserFileSystem(cmd *cobra.Command) *core.FileSystem {
	if f == nil {
		user := User(cmd)
		db := db.Get(context.Background())
		if user == nil {
			f = core.OpenSUFileSystem(db)
		} else {
			f = core.OpenFileSystem(db, uuid.Nil, u.Home, u.ID, u.Privileges, []string{"*"})
		}
	}
	return f
}
