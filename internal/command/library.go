package command

import (
	"context"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupLibraryCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "library",
		Short: "Library Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupLibraryCreateCommand(),
		setupLibraryDeleteCommand(),
	}...)
	return cmd
}

func setupLibraryCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create name",
		Short: "Create Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := libraryManager.Create(context.Background(), uuid.New(), args[0]); err != nil {
				logrus.Fatal(err)
			}
		},
	}
}

func setupLibraryDeleteCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "delete name",
		Short: "Delete Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := libraryManager.Delete(context.Background(), args[0]); err != nil {
				logrus.Fatal(err)
			}
		},
	}
}
