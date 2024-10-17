package command

import (
	"context"
	"fmt"
	"os"
	"strconv"

	"github.com/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

func setupSchemaCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "schema",
		Short: "Database Schema Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupSchemaMigrateCommand(),
		setupSchemaResetCommand(),
	}...)
	return cmd
}

func setupSchemaResetCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "reset",
		Short: "Reset Database Schema",
		Run: func(cmd *cobra.Command, args []string) {
			if err := db.Default.DeleteSchema(context.Background()); err != nil {
				fmt.Println(err.Error())
				os.Exit(1)
			}
		},
	}
}

func setupSchemaMigrateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "migrate",
		Short: "Migrate Database Schema",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := context.Background()
			if args[0] == "auto" || args[0] == "latest" {
				if err := db.Default.CheckVersion(ctx, true); err != nil {
					fmt.Println(err.Error())
					os.Exit(2)
				}
			} else {
				db.Default.CheckVersion(ctx, false)
				if v, err := strconv.Atoi(args[0]); err != nil {
					fmt.Println(err.Error())
					os.Exit(3)
				} else if err := db.Default.Migrate(ctx, v); err != nil {
					fmt.Println(err.Error())
					os.Exit(4)
				}
			}
		},
	}
}
