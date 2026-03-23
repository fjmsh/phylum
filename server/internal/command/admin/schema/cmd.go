package schema

import (
	"context"
	"fmt"
	"os"
	"strconv"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

var DBConfig db.Config

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
			ctx := context.Background()
			if pool, err := db.Connect(ctx, DBConfig, nil); err != nil {
				fmt.Println(err.Error())
				os.Exit(1)
			} else {
				if err := db.ResetSchema(context.Background(), pool); err != nil {
					fmt.Println("unable to delete database schema: " + err.Error())
					os.Exit(1)
				}
				fmt.Println("Database schema successfully reset")
			}
		},
	}
}

func setupMigrateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "migrate",
		Short: "Migrate Schema",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := context.Background()
			if pool, err := db.Connect(ctx, DBConfig, nil); err != nil {
				fmt.Println(err.Error())
				os.Exit(1)
			} else if s, err := db.GetSchemaInfo(ctx, pool); err != nil {
				fmt.Println(err.Error())
				os.Exit(1)
			} else {
				v := s.LatestVersion
				if len(args) == 1 {
					version, err := strconv.Atoi(args[0])
					if err != nil {
						fmt.Println("failed to parse target version: " + err.Error())
						os.Exit(1)
					}
					v = int32(version)
				}
				if s.CurrentVersion == v {
					if len(args) == 1 {
						fmt.Println("Database schema is already at the requested version")
					} else {
						fmt.Println("Database schema is up-to-date")
					}
				} else if err := s.MigrateTo(ctx, v); err != nil {
					fmt.Println("failed to perform migration: " + err.Error())
					os.Exit(1)
				} else {
					fmt.Printf("Database schema successfully migrated to version %d\n", v)
				}
			}
		},
	}
}
