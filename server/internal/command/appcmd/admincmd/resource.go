package admincmd

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupResourceCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "resource",
		Short: "Resource Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupResourceMkdirCommand(),
		setupSiloListCommand(),
		setupSiloDeleteCommand(),
	}...)
	return cmd
}

func setupResourceMkdirCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "mkdir path",
		Short: "Create Directory",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			fs, err := app.Default.OpenFileSystem(context.Background(), 0)
			if err != nil {
				logrus.Fatal(err)
			}
			if _, err := fs.ResourceByPath(path); err == nil {
				logrus.Fatal("Resource already exists: " + path)
			}
			// Streamline with WebDAV mkcol request handling
			path = strings.TrimRight(path, "/")
			index := strings.LastIndex(path, "/")
			parentPath := path[0:index]
			parent, err := fs.ResourceByPath(parentPath)

			if err != nil {
				logrus.Fatal("Parent resource does not exist: " + parentPath)
			}

			id := uuid.New()
			name := path[index+1:]
			if _, err = fs.CreateMemberResource(parent, id, name, true); err != nil {
				logrus.Fatal(err)
			} else {
				logrus.Info("Created directory " + path + " (" + id.String() + ")")
			}
		},
	}
}

func setupSiloListCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List Silos",
		Args:  cobra.ExactArgs(0),
		Run: func(cmd *cobra.Command, args []string) {
		},
	}
}

func setupSiloDeleteCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "delete id",
		Short: "Delete Silo",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
		},
	}
}
