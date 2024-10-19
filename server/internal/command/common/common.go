package common

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/spf13/viper"
)

func MustInitializeDB(autoMigrate bool) {
	databaseURL := viper.GetString("database_url")
	traceSQL := viper.GetBool("debug") && viper.GetBool("trace_sql")
	if err := db.Initialize(context.Background(), databaseURL, traceSQL, autoMigrate); err != nil {
		fmt.Println("could create database: " + err.Error())
		os.Exit(1)
	}
}

func MustInitializeStorage() {
	MustInitializeDB(true)
	if err := storage.Initialize(context.Background(), db.Default, viper.GetString("default_storage_dir")); err != nil {
		fmt.Println("could not open storage: " + err.Error())
		os.Exit(2)
	}
}

func MustInitializeApp() {
	MustInitializeStorage()
	if err := app.Initialize(context.Background(), db.Default, storage.Default); err != nil {
		fmt.Println("could not initialize app: " + err.Error())
		os.Exit(3)
	}
}
