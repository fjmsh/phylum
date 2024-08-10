package appcmd

import (
	"context"
	"errors"
	"fmt"
	iofs "io/fs"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var fs core.FileSystem

func setupResourceCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "resource",
		Short: "Resource Management",
	}

	cmd.AddCommand([]*cobra.Command{
		setupResourceMkdirCommand(),
		setupResourceRmCommand(),
		setupResourceLsCommand(),
		setupResourceChpermCommand(),
	}...)
	return cmd
}

func setupResourceMkdirCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "mkdir path",
		Short: "Create Directory",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
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
	setupUserFlags(&cmd)

	return &cmd
}

func setupResourceRmCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "rm path",
		Short: "Delete Resource",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
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
	setupUserFlags(&cmd)

	return &cmd
}

func setupResourceLsCommand() *cobra.Command {
	details := func(r core.Resource) string {
		return fmt.Sprintf("%s %4d %s", r.ID().String(), r.Permission(), r.Name())
	}
	cmd := cobra.Command{
		Use:   "ls <path | uuid>",
		Short: "List Resource Details",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
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

			specificPermissions, err := fs.GetPermissionsLocal(r)
			if err != nil {
				logrus.Fatal(err)
			}
			inheritedPermissions, err := fs.GetPermissionsInherited(r)
			if err != nil {
				logrus.Fatal(err)
			}

			logrus.Info("Name: " + r.Name())
			logrus.Info("  ID: " + r.ID().String())
			logrus.Info("Perm: " + core.PermissionString(r.Permission()))

			if specificPermissions != nil {
				logrus.Info()
				logrus.Info("Specific Permissions:")
				for id, p := range specificPermissions {
					user, err := core.Default.UserByID(context.Background(), id)
					if err != nil {
						logrus.Fatal(err)
					}
					logrus.Info(fmt.Sprintf("%8.8s (%3.3d): %s", user.Email(), user.ID(), core.PermissionString(p)))
				}
			}

			if inheritedPermissions != nil {
				logrus.Info()
				logrus.Info("Inherited Permissions:")
				for id, p := range inheritedPermissions {
					user, err := core.Default.UserByID(context.Background(), id)
					if err != nil {
						logrus.Fatal(err)
					}
					logrus.Info(fmt.Sprintf("%8.8s (%3.3d): %s", user.Email(), user.ID(), core.PermissionString(p)))
				}
			}

			if r.IsDir() {
				children, err := fs.ReadDir(r)
				if err != nil {
					logrus.Fatal(err)
				}
				logrus.Info()
				logrus.Info("Children:")
				for _, c := range children {
					logrus.Info(details(c))
				}
			}
		},
	}
	setupUserFlags(&cmd)

	return &cmd
}

func setupResourceChpermCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "chperm user <path | uuid> [ none | read | write | share ]",
		Short: "Change Resource Permissions",
		Args:  cobra.ExactArgs(3),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			var user int32
			if u, err := core.Default.UserByEmail(context.Background(), args[0]); err != nil {
				logrus.Fatal(err)
			} else {
				user = u.ID()
			}

			var r core.Resource
			path := args[1]
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

			permission := core.PermissionNone
			switch args[2] {
			case "none":
			case "read":
				permission = core.PermissionReadOnly
			case "write":
				permission = core.PermissionReadWrite
			case "share":
				permission = core.PermissionReadWriteShare
			default:
				logrus.Fatal("Unrecognized premission: " + args[2])
			}

			if err := fs.UpdatePermissions(r, user, permission); err != nil {
				logrus.Fatal(err)
			}
		},
	}
	setupUserFlags(&cmd)

	return &cmd
}

func openFileSystemFromFlags(cmd *cobra.Command) {
	var user core.User
	if value, err := cmd.Flags().GetString("user"); err != nil {
		logrus.Fatal(err)
	} else {
		if u, err := core.Default.UserByEmail(context.Background(), value); err != nil {
			logrus.Fatal(err)
		} else {
			user = u
		}
	}

	var err error
	fs, err = core.Default.OpenFileSystem(context.Background(), user)
	if err != nil {
		logrus.Fatal(err)
	}

}

func setupUserFlags(cmd *cobra.Command) {
	flags := cmd.Flags()
	flags.StringP("user", "u", "phylum", "Specify user for resource operations")

}
