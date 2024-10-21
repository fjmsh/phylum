package storage

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "storage",
		Short: "Storage Management",
	}
	flags := cmd.PersistentFlags()
	flags.Bool("auto-migrate", true, "Automatically migrate database schema")
	viper.BindPFlag("auto_migrate", flags.Lookup("auto-migrate"))

	flags.StringP("default-storage-dir", "S", "storage/default", "Default Storage Directory")
	viper.BindPFlag("default_storage_dir", flags.Lookup("default-storage-dir"))

	cmd.AddCommand([]*cobra.Command{
		setupStorageCreateCommand(),
		setupStorageListCommand(),
	}...)

	return cmd
}

func setupStorageCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create name driver",
		Short: "Create new storage backend",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			name := args[0]
			driver := args[1]
			paramNames, err := storage.ParamNames(driver)
			if err != nil {
				logrus.Fatal(err)
			}

			params := map[string]string{}
			reader := bufio.NewReader(os.Stdin)
			for _, paramName := range paramNames {
				os.Stdout.WriteString(paramName + ": ")
				val, err := reader.ReadString('\n')
				if err != nil {
					logrus.Fatal(err)
				}
				val = strings.TrimSpace(val)
				params[paramName] = val
			}

			if err := storage.Get().CreateBackend(context.Background(), name, driver, params); err != nil {
				logrus.Fatal(err)
			}

			logrus.Info("Storage backend created: " + name)
		},
	}
}

func setupStorageListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List all storage backends",
		Run: func(cmd *cobra.Command, args []string) {
			logrus.Info("Available storage backends:")
			for k, v := range storage.Get().ListBackends() {
				logrus.Info(fmt.Sprintf("%s: %s", k, v))
			}
		},
	}
}
