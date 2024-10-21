package common

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

var s storage.Storage
var a app.App
var f fs.FileSystem

func DB() *db.DbHandler {
	return db.Get()
}

func Storage() storage.Storage {
	return storage.Get()
}

func App() app.App {
	if a == nil {
		if app, err := app.Create(context.Background(), DB(), Storage()); err != nil {
			fmt.Println("could not initialize app: " + err.Error())
			os.Exit(3)
		} else {
			a = app
		}
	}
	return a
}

func RootFileSystem() fs.FileSystem {
	var rootUser user.User
	if user, err := user.CreateManager(context.Background()).UserByEmail(user.DefaultUserUsername); err != nil {
		fmt.Println("unable to find root user: " + err.Error())
		os.Exit(1)
	} else {
		rootUser = user
	}

	return App().OpenFileSystem(context.Background(), rootUser)
}

func UserFileSystem(cmd *cobra.Command) fs.FileSystem {
	if f == nil {
		if value, err := cmd.Flags().GetString("user"); err != nil {
			fmt.Println("could not read user: " + err.Error())
			os.Exit(4)
		} else {
			if u, err := user.CreateManager(context.Background()).UserByEmail(value); err != nil {
				fmt.Println("could not find user '" + value + "': " + err.Error())
				os.Exit(5)
			} else {
				f = App().OpenFileSystem(context.Background(), u)
			}
		}
	}
	return f
}
