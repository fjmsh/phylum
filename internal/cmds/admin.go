package cmds

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/phylumsql"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupAdminCommand() *cobra.Command {
	var cmdServe = &cobra.Command{
		Use:   "admin",
		Short: "Server Administration",
	}
	cmdServe.AddCommand([]*cobra.Command{setupAdminMkrootCommand()}...)

	return cmdServe
}

func setupAdminMkrootCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "mkroot name",
		Short: "Create Root Folder",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			name := args[0]
			if _, err := queries.FindRoot(context.Background(), name); err == nil {
				log.Fatal(fmt.Sprintf("Root directory already exists: %s", name))
			} else {
				_, err = queries.CreateDirectory(context.Background(), phylumsql.CreateDirectoryParams{ID: uuid.New(), Parent: nil, Name: name})
				if err != nil {
					log.Fatal(err)
				} else {
					log.Info(fmt.Sprintf("Root directory created: %s", name))
				}
			}
		},
	}
}
