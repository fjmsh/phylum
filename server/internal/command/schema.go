package command

import (
	"context"
	"strconv"

	"github.com/shroff/phylum/server/internal/db"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupSchemaCommand(db **db.DbHandler) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "schema",
		Short: "Database Schema Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupSchemaMigrateCommand(db),
		setupSchemaResetCommand(db),
		setupSchemaTestCommand(db),
	}...)
	return cmd
}

func setupSchemaTestCommand(dbh **db.DbHandler) *cobra.Command {
	return &cobra.Command{
		Use:   "test",
		Short: "Test Database Schema",
		Run: func(cmd *cobra.Command, args []string) {
		},
	}
}

func setupSchemaResetCommand(db **db.DbHandler) *cobra.Command {
	return &cobra.Command{
		Use:   "reset",
		Short: "Reset Database Schema",
		Run: func(cmd *cobra.Command, args []string) {
			if err := (*db).DeleteSchema(context.Background()); err != nil {
				logrus.Fatal(err)
			}
		},
	}
}

func setupSchemaMigrateCommand(db **db.DbHandler) *cobra.Command {
	return &cobra.Command{
		Use:   "migrate",
		Short: "Migrate Database Schema",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := context.Background()
			if args[0] == "auto" || args[0] == "latest" {
				if err := (*db).CheckVersion(ctx, true); err != nil {
					logrus.Fatal(err)
				}
			} else {
				(*db).CheckVersion(ctx, false)
				v, err := strconv.Atoi(args[0])
				if err != nil {
					logrus.Fatal(err)
				}
				if err = (*db).Migrate(ctx, v); err != nil {
					logrus.Fatal(err)
				}
			}
		},
	}
}
