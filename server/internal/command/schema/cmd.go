package schema

import (
	"context"
	"fmt"
	"os"
	"strconv"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() *cobra.Command {
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
			viper.Set("auto_migrate", false)
			if err := common.DB().DeleteSchema(context.Background()); err != nil {
				fmt.Println("unable to delete database schema: " + err.Error())
				os.Exit(1)
			}
			if err := common.DB().Migrate(context.Background(), -1); err != nil {
				fmt.Println("unable to migrate database schema: " + err.Error())
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
				viper.Set("auto_migrate", true)
				common.DB()
			} else {
				viper.Set("auto_migrate", false)
				if v, err := strconv.Atoi(args[0]); err != nil {
					fmt.Println(err.Error())
					os.Exit(3)
				} else if err := common.DB().Migrate(ctx, v); err != nil {
					fmt.Println(err.Error())
					os.Exit(4)
				}
			}
		},
	}
}
