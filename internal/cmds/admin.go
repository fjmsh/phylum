package cmds

import (
	"context"

	"github.com/google/uuid"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupAdminCommand() *cobra.Command {
	var cmdServe = &cobra.Command{
		Use:   "admin",
		Short: "Server Administration",
	}
	cmdServe.AddCommand([]*cobra.Command{
		setupAdminMkrootCommand(),
		setupAdminRmrootCommand(),
	}...)

	return cmdServe
}

func setupAdminMkrootCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "mkroot name",
		Short: "Create Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := vfsManager.CreateVfs(context.Background(), uuid.New(), args[0]); err != nil {
				log.Fatal(err)
			}
		},
	}
}

func setupAdminRmrootCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "rmroot name",
		Short: "Delete Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if err := vfsManager.DeleteVfs(context.Background(), args[0]); err != nil {
				log.Fatal(err)
			}
		},
	}
}
