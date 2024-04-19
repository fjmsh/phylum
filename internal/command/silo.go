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
		setupLibraryDeleteCommand(),
	}...)
	return cmd
}

func setupSiloCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create storage-backend owner display-name",
		Short: "Create Library",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			id := uuid.New()

			storageName := args[0]
			storage := storageManager.Find(storageName)
			if storage == nil {
				logrus.Fatal("Storage not found: " + storageName)
			}

			username := args[1]
			user, err := userManager.FindUser(context.Background(), username)
			if err != nil {
				logrus.Fatal("User not found: " + username)
			}
			name := args[2]
			if err := fs.CreateSilo(context.Background(), id, user.ID, storageName, name); err != nil {
				logrus.Fatal(err)
			}
			logrus.Info("Created " + id.String())
		},
	}
}

func setupLibraryDeleteCommand() *cobra.Command {
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
