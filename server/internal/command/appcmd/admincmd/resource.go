package admincmd

import (
	"context"
	"errors"
	iofs "io/fs"
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
		setupResourceRmCommand(),
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

func setupResourceRmCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "rm path",
		Short: "Delete Resource",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			fs, err := app.Default.OpenFileSystem(context.Background(), 0)
			if err != nil {
				logrus.Fatal(err)
			}
			r, err := fs.ResourceByPath(path)
			if err != nil {
				if errors.Is(err, iofs.ErrNotExist) {
					logrus.Fatal("Resource not found: " + path)
				} else {
					logrus.Fatal(err.Error())
				}
			}

			if r.IsDir() {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					logrus.Fatal("Must use -r to delete collections")
				}
			}

			fs.DeleteRecursive(r, true)
		},
	}
	flags := cmd.Flags()
	flags.BoolP("recursive", "r", false, "Recursively delete resource (required for collections)")

	return &cmd
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
