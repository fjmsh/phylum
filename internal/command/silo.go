package command

import (
	"context"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupSiloCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "silo",
		Short: "Silo Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupSiloCreateCommand(),
		setupSiloListCommand(),
		setupSiloDeleteCommand(),
	}...)
	return cmd
}

func setupSiloCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create owner storage name",
		Short: "Create Silo",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			id := uuid.New()

			username := args[0]
			user, err := userManager.FindUser(context.Background(), username)
			if err != nil {
				logrus.Fatal("User not found: " + username)
			}

			storageName := args[1]
			storage := storageManager.Find(storageName)
			if storage == nil {
				logrus.Fatal("Storage not found: " + storageName)
			}

			name := args[2]
			if err := fs.CreateSilo(context.Background(), id, user.Username, storageName, name); err != nil {
				logrus.Fatal(err)
			}
			logrus.Info("Created " + id.String())
		},
	}
}

func setupSiloListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List Silos",
		Args:  cobra.ExactArgs(0),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := context.Background()
			silos, err := fs.ListSilos(ctx)
			if err != nil {
				logrus.Fatal(err)
			}
			for _, silo := range silos {
				logrus.Infof("%-16s: %s\n", silo.Name, silo.ID.String())
				logrus.Infof("  storage: %s\n", silo.Storage)
				logrus.Infof("  owner: %s\n", silo.Owner)
				logrus.Info()
			}
		},
	}
}

func setupSiloDeleteCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "delete id",
		Short: "Delete Silo",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			id, err := uuid.Parse(args[0])
			if err != nil {
				logrus.Fatal("Not an ID: " + args[0])
			}
			if err := fs.DeleteSilo(context.Background(), id); err != nil {
				logrus.Fatal(err)
			}
		},
	}
}
