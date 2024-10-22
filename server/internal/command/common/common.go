package common

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

var u user.User
var f fs.FileSystem

func RootFileSystem() fs.FileSystem {
	var rootUser user.User
	if user, err := user.CreateManager(context.Background()).UserByEmail(db.DefaultUserUsername); err != nil {
		fmt.Println("unable to find root user: " + err.Error())
		os.Exit(1)
	} else {
		rootUser = user
	}

	return rootUser.OpenFileSystem(context.Background())
}

func User(cmd *cobra.Command) user.User {
	if u.Username == "" {
		if value, err := cmd.Flags().GetString("user"); err != nil {
			fmt.Println("could not read user: " + err.Error())
			os.Exit(1)
		} else {
			if user, err := user.CreateManager(context.Background()).UserByEmail(value); err != nil {
				fmt.Println("could not find user '" + value + "': " + err.Error())
				os.Exit(1)
			} else {
				u = user
			}
		}
	}
	return u
}

func UserFileSystem(cmd *cobra.Command) fs.FileSystem {
	if f == nil {
		f = User(cmd).OpenFileSystem(context.Background())
	}
	return f
}
