package command

import (
	"strconv"

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
	}...)
	return cmd
}

func setupSchemaMigrateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "migrate",
		Short: "Migrate Database Schema",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			v, err := strconv.Atoi(args[0])
			if err != nil {
				logrus.Fatal(err)
			}
			if err = db.Migrate(v); err != nil {
				logrus.Fatal(err)
			}
		},
	}
}
