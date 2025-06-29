package storage

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/storage"
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
				fmt.Printf("storage driver %q does not exist\n", name)
				os.Exit(1)
			}

			params := map[string]string{}
			reader := bufio.NewReader(os.Stdin)
			for _, paramName := range driver.Params {
				os.Stdout.WriteString(paramName + ": ")
				val, err := reader.ReadString('\n')
				if err != nil {
					fmt.Printf("failed to read parameter %q: %s\n", paramName, err.Error())
					os.Exit(1)
				}
				val = strings.TrimSpace(val)
				params[paramName] = val
			}

			if err := storage.InsertBackend(db.Get(context.Background()), name, driver, params); err != nil {
				fmt.Printf("failed to insert: %s\n", err.Error())
				os.Exit(1)
			}

			fmt.Println("Storage backend created: " + name)
		},
	}
}

func setupListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List all storage backends",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Available storage backends:")
			for k, v := range storage.ListBackends() {
				fmt.Printf("%s: %s\n", k, v)
			}
		},
	}
}
