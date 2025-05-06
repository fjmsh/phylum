package common

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

var u *user.User
var f fs.FileSystem

func RootFileSystem() fs.FileSystem {
	return fs.OpenOmniscient(context.Background())
}

func User(cmd *cobra.Command) *user.User {
	if u == nil {
		if value, err := cmd.Flags().GetString("user"); err != nil {
			fmt.Println("could not read user: " + err.Error())
			os.Exit(1)
		} else if value == "" {
			u = nil
		} else {
			if user, err := user.ManagerFromContext(context.Background()).UserByEmail(value); err != nil {
				fmt.Println("could not find user '" + value + "': " + err.Error())
				os.Exit(1)
			} else {
				u = &user
			}
		}
	}
	return u
}

func UserFileSystem(cmd *cobra.Command) fs.FileSystem {
	if f == nil {
		user := User(cmd)
		if user == nil {
			f = fs.OpenOmniscient(context.Background())
		} else {
			f = user.OpenFileSystem(context.Background())
		}
	}
	return f
}
