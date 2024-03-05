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
		setupAdminVfsCommand(),
	}...)

	return cmd
}

func setupAdminVfsCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "vfs",
		Short: "VFS Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupAdminVfsCreateCommand(),
		setupAdminVfsDeleteCommand(),
	}...)
	return cmd
}

func setupAdminVfsCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create name",
		Short: "Create Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := vfsManager.CreateVfs(context.Background(), uuid.New(), args[0]); err != nil {
				log.Fatal(err)
			}
		},
	}
}

func setupAdminVfsDeleteCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "delete name",
		Short: "Delete Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := vfsManager.DeleteVfs(context.Background(), args[0]); err != nil {
				log.Fatal(err)
			}
		},
	}
}
