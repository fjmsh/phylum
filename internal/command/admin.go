package command

import (
	"context"

	"github.com/google/uuid"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupAdminCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "admin",
		Short: "Server Administration",
	}
	cmd.AddCommand([]*cobra.Command{
		setupAdminLibraryCommand(),
	}...)

	return cmd
}

func setupAdminLibraryCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "library",
		Short: "Library Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupAdminLibraryCreateCommand(),
		setupAdminLibraryDeleteCommand(),
	}...)
	return cmd
}

func setupAdminLibraryCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create name",
		Short: "Create Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := libraryManager.Create(context.Background(), uuid.New(), args[0]); err != nil {
				log.Fatal(err)
			}
		},
	}
}

func setupAdminLibraryDeleteCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "delete name",
		Short: "Delete Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := libraryManager.Delete(context.Background(), args[0]); err != nil {
				log.Fatal(err)
			}
		},
	}
}
