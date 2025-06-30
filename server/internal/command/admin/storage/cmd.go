package storage

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strconv"
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
	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create new storage backend",
		Args:  cobra.ExactArgs(1),
	}

	cmd.Run = func(cmd *cobra.Command, args []string) {
		reader := bufio.NewReader(os.Stdin)
		name, _ := cmd.Flags().GetString("name")
		if name == "" {
			fmt.Print("Name: ")
			if val, err := reader.ReadString('\n'); err != nil {
				fmt.Println("failed to read stdin: " + err.Error())
				os.Exit(1)
			} else {
				name = strings.TrimSpace(val)
			}
		}
		fmt.Println(name)
		if _, err := storage.GetBackend(name); err == nil {
			fmt.Printf("storage backend %q already exists\n", name)
			os.Exit(1)
		}

		var driver storage.Driver
		if dr, _ := cmd.Flags().GetString("storage-driver"); dr != "" {
			if d, err := storage.FindDriver(dr); err != nil {
				fmt.Printf("storage driver %q does not exist\n", dr)
				os.Exit(1)
			} else {
				driver = d
			}
		} else {
			drivers := storage.ListDrivers()
			fmt.Println("Storage Driver: ")
			for i, d := range drivers {
				fmt.Printf("%-d) %s\n", i+1, d.Description)
			}

			fmt.Printf("Enter your choice [1-%d]: ", len(drivers))

			if val, err := reader.ReadString('\n'); err != nil {
				fmt.Println("failed to read stdin: " + err.Error())
				os.Exit(1)
			} else if i, err := strconv.Atoi(strings.TrimSpace(val)); err != nil {
				fmt.Println("failed to parse input: " + err.Error())
				os.Exit(1)
			} else if i <= 0 || int(i) > len(drivers) {
				fmt.Println("selection out of range")
				os.Exit(1)
			} else {
				driver = drivers[i]
			}
		}

		params := map[string]string{}
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
	}

	cmd.Flags().StringP("name", "n", "", "Backend Name")
	cmd.Flags().StringP("storage-driver", "d", "", "Storage Driver")

	return cmd
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
