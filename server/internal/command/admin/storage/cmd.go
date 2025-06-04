package storage

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "storage",
		Short: "Storage Management",
	}

	cmd.AddCommand([]*cobra.Command{
		setupCreateCommand(),
		setupListCommand(),
	}...)

	return cmd
}

func setupCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create name driver",
		Short: "Create new storage backend",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			name := args[0]
			driverName := args[1]
			driver, err := storage.FindDriver(driverName)
			if err != nil {
				logrus.Fatal(err)
			}

			params := map[string]string{}
			reader := bufio.NewReader(os.Stdin)
			for _, paramName := range driver.Params {
				os.Stdout.WriteString(paramName + ": ")
				val, err := reader.ReadString('\n')
				if err != nil {
					logrus.Fatal(err)
				}
				val = strings.TrimSpace(val)
				params[paramName] = val
			}

			if err := storage.InsertBackend(db.Get(context.Background()), name, driver, params); err != nil {
				logrus.Fatal(err)
			}

			logrus.Info("Storage backend created: " + name)
		},
	}
}

func setupListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List all storage backends",
		Run: func(cmd *cobra.Command, args []string) {
			logrus.Info("Available storage backends:")
			for k, v := range storage.ListBackends() {
				logrus.Info(fmt.Sprintf("%s: %s", k, v))
			}
		},
	}
}
