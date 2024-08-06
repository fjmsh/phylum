package appcmd

import (
	"context"
	"errors"
	"fmt"
	iofs "io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/app"
	"github.com/shroff/phylum/server/internal/app/core"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var userID int32

func setupResourceCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "resource",
		Short: "Resource Management",
	}

	cmd.AddCommand([]*cobra.Command{
		setupResourceMkdirCommand(),
		setupResourceRmCommand(),
		setupResourceLsCommand(),
	}...)
	return cmd
}

func setupResourceMkdirCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "mkdir path",
		Short: "Create Directory",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			readUserIDFromFlagsreadUsername(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			fs, err := app.Default.OpenFileSystem(context.Background(), userID)
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
	setupUsernameFlags(&cmd)

	return &cmd
}

func setupResourceRmCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "rm path",
		Short: "Delete Resource",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			readUserIDFromFlagsreadUsername(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			fs, err := app.Default.OpenFileSystem(context.Background(), userID)
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
	setupUsernameFlags(&cmd)

	return &cmd
}

func setupResourceLsCommand() *cobra.Command {
	details := func(r core.Resource, name string) string {
		return fmt.Sprintf("%4d %s %s", r.Permission(), r.ID().String(), name)
	}
	cmd := cobra.Command{
		Use:   "ls <path | uuid>",
		Short: "List Resource Details",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			readUserIDFromFlagsreadUsername(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			fs, err := app.Default.OpenFileSystem(context.Background(), userID)
			if err != nil {
				logrus.Fatal(err)
			}
			var r core.Resource
			if path[0] != '/' {
				var id uuid.UUID
				var err error
				if id, err = uuid.Parse(path); err != nil {
					logrus.Fatal(err)
				}

				if r, err = fs.ResourceByID(id); err != nil {
					if errors.Is(err, iofs.ErrNotExist) {
						logrus.Fatal("Resource not found: " + path)
					} else {
						logrus.Fatal(err.Error())
					}
				}
			} else {
				var err error
				if r, err = fs.ResourceByPath(path); err != nil {
					if errors.Is(err, iofs.ErrNotExist) {
						logrus.Fatal("Resource not found: " + path)
					} else {
						logrus.Fatal(err.Error())
					}
				}
			}

			if r.IsDir() {
				children, err := fs.ReadDir(r)
				if err != nil {
					logrus.Fatal(err)
				}
				logrus.Info(details(r, "."))
				for _, c := range children {
					logrus.Info(details(c, c.Name()))
				}
			} else {
				logrus.Info(details(r, r.Name()))
			}
		},
	}
	setupUsernameFlags(&cmd)

	return &cmd
}

func readUserIDFromFlagsreadUsername(cmd *cobra.Command) {
	if value, err := cmd.Flags().GetInt32("user"); err != nil {
		logrus.Fatal(err)
	} else if value != 0 {
		if user, err := app.Default.UserByID(context.Background(), value); err != nil {
			logrus.Fatal(err)
		} else {
			userID = user.ID()
			return
		}
	}

	if value, err := cmd.Flags().GetString("username"); err != nil {
		logrus.Fatal(err)
	} else {
		if user, err := app.Default.UserByUsername(context.Background(), value); err != nil {
			logrus.Fatal(err)
		} else {
			userID = user.ID()
		}
	}

}

func setupUsernameFlags(cmd *cobra.Command) {
	flags := cmd.Flags()
	flags.Int32P("user", "u", 0, "Specify User ID for resource operations (cannot be used with -U)")
	flags.StringP("username", "U", "root", "Specify Username for resource operations (cannot be used with -u)")

}
