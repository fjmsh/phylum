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
	"github.com/spf13/viper"
)

var d *db.DbHandler
var s storage.Storage
var a *app.App
var f fs.FileSystem

func DB() *db.DbHandler {
	if d == nil {
		databaseURL := viper.GetString("database_url")
		traceSQL := viper.GetBool("debug") && viper.GetBool("trace_sql")
		autoMigrate := viper.GetBool("auto_migrate")
		if db, err := db.Create(context.Background(), databaseURL, traceSQL, autoMigrate); err != nil {
			fmt.Println("could create database: " + err.Error())
			os.Exit(1)
		} else {
			d = db
		}
	}
	return d
}

func Storage() storage.Storage {
	if s == nil {
		if storage, err := storage.Create(context.Background(), DB(), viper.GetString("default_storage_dir")); err != nil {
			fmt.Println("could not open storage: " + err.Error())
			os.Exit(2)
		} else {
			s = storage
		}
	}
	return s
}

func App() *app.App {
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
	if user, err := App().OpenUserManager(context.Background()).UserByEmail(user.DefaultUserUsername); err != nil {
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
			if user, err := App().OpenUserManager(context.Background()).UserByEmail(value); err != nil {
				fmt.Println("could not find user '" + value + "': " + err.Error())
				os.Exit(5)
			} else {
				f = App().OpenFileSystem(context.Background(), user)
			}
		}
	}
	return f
}
