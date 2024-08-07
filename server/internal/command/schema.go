package command

import (
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
	}...)
	return cmd
}

func setupSchemaResetCommand(db **db.DbHandler) *cobra.Command {
	return &cobra.Command{
		Use:   "reset",
		Short: "Reset Database Schema",
		Run: func(cmd *cobra.Command, args []string) {
			if err := (*db).DeleteSchema(); err != nil {
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
			if args[0] == "auto" || args[0] == "latest" {
				if err := (*db).CheckVersion(true); err != nil {
					logrus.Fatal(err)
				}
			} else {
				(*db).CheckVersion(false)
				v, err := strconv.Atoi(args[0])
				if err != nil {
					logrus.Fatal(err)
				}
				if err = (*db).Migrate(v); err != nil {
					logrus.Fatal(err)
				}
			}
		},
	}
}
