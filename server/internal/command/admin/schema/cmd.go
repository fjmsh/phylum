package schema

import (
	"context"
	"fmt"
	"os"
	"strconv"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "schema",
		Short: "Database Schema Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupMigrateCommand(),
		setupResetCommand(),
	}...)
	return cmd
}

func setupResetCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "reset",
		Short: "Reset Schema",
		Run: func(cmd *cobra.Command, args []string) {
			db.Cfg.NoMigrate = true
			if err := db.DeleteSchema(context.Background()); err != nil {
				fmt.Println("unable to delete database schema: " + err.Error())
				os.Exit(1)
			}
			if err := db.Migrate(context.Background(), -1); err != nil {
				fmt.Println("unable to migrate database schema: " + err.Error())
				os.Exit(1)
			}
		},
	}
}

func setupMigrateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "migrate",
		Short: "Migrate Schema",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := context.Background()
			if args[0] == "auto" || args[0] == "latest" {
				db.Cfg.NoMigrate = false
				db.Get(ctx)
			} else {
				db.Cfg.NoMigrate = true
				if v, err := strconv.Atoi(args[0]); err != nil {
					fmt.Println(err.Error())
					os.Exit(3)
				} else if err := db.Migrate(ctx, v); err != nil {
					fmt.Println(err.Error())
					os.Exit(4)
				}
			}
		},
	}
}
