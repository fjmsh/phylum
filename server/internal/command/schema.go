package command

import (
	"context"
	"strconv"

	"github.com/shroff/phylum/server/internal/db"
	"github.com/sirupsen/logrus"
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
				logrus.Fatal(err)
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
					logrus.Fatal(err)
				}
			} else {
				db.Default.CheckVersion(ctx, false)
				v, err := strconv.Atoi(args[0])
				if err != nil {
					logrus.Fatal(err)
				}
				if err = db.Default.Migrate(ctx, v); err != nil {
					logrus.Fatal(err)
				}
			}
		},
	}
}
