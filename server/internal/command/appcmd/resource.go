package appcmd

import (
	"context"
	"errors"
	"fmt"
	"sort"
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
		setupResourceCpCommand(),
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
			// TODO: Streamline with WebDAV mkcol request handling
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
				if errors.Is(err, core.ErrResourceNotFound) {
					logrus.Fatal("Resource not found: " + path)
				} else {
					logrus.Fatal(err.Error())
				}
			}

			if r.Dir {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					logrus.Fatal("Must use -r to delete directories")
				}
			}

			fs.DeleteRecursive(r, true)
		},
	}
	flags := cmd.Flags()
	flags.BoolP("recursive", "r", false, "Recursive (required for directories)")
	setupUserFlags(&cmd)

	return &cmd
}

func setupResourceLsCommand() *cobra.Command {
	formatSize := func(size int64) string {
		suffix := []string{"", "K", "M", "G", "T"}
		si := 0
		for ; size >= 1000 && si < len(suffix); si, size = si+1, size/1000 {
		}
		return fmt.Sprintf("%4d%s", size, suffix[si])
	}
	details := func(r core.Resource) string {
		name := r.Name
		if r.Dir {
			name += "/"
		}
		return fmt.Sprintf("%s %s %s %s", r.ID.String(), formatSize(r.ContentSize), name, r.Permissions)
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
					if errors.Is(err, core.ErrResourceNotFound) {
						logrus.Fatal("Resource not found: " + path)
					} else {
						logrus.Fatal(err.Error())
					}
				}
			} else {
				var err error
				if r, err = fs.ResourceByPath(path); err != nil {
					if errors.Is(err, core.ErrResourceNotFound) {
						logrus.Fatal("Resource not found: " + path)
					} else {
						logrus.Fatal(err.Error())
					}
				}
			}

			logrus.Info("         Name: " + r.Name)
			logrus.Info("           ID: " + r.ID.String())
			logrus.Info("  Permissions: " + r.Permissions)
			logrus.Info("    Inherited: " + r.InheritedPermissions)

			if r.Dir {
				children, err := fs.ReadDir(r)
				if err != nil {
					logrus.Fatal(err)
				}
				logrus.Info()
				logrus.Info("Children:")
				sort.Slice(children, func(i, j int) bool {
					a := children[i]
					b := children[j]
					if a.Dir != b.Dir {
						if a.Dir {
							return true
						}
					}
					return strings.Compare(strings.ToLower(a.Name), strings.ToLower((b.Name))) <= 0
				})
				// children = sort.Slice(children, func(a core.Resource, b core.Resource) bool {
				// 	return true
				// })
				for _, c := range children {
					logrus.Info(details(c))
				}
			} else {
				logrus.Info(fmt.Sprintf("         Size: %d", r.ContentSize))
				logrus.Info(" Content Type: " + r.ContentType)
				logrus.Info("   SHA256 Sum: " + r.ContentSHA256)
			}
		},
	}
	setupUserFlags(&cmd)

	return &cmd
}

func setupResourceCpCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "cp <src> <dest>",
		Short: "Copy Resource",
		Args:  cobra.ExactArgs(2),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			srcPath := strings.TrimRight(args[0], "/")
			src, err := fs.ResourceByPath(srcPath)
			if err != nil {
				if errors.Is(err, core.ErrResourceNotFound) {
					logrus.Fatal("Resource not found: " + srcPath)
				}
				logrus.Fatal(err.Error())
			}
			var parentID uuid.UUID
			var name string
			parentPath := strings.TrimRight(args[1], "/")
			if dest, err := fs.ResourceByPath(parentPath); err == nil {
				if dest.Dir {
					parentID = dest.ID
					name = src.Name
				} else if src.Dir {
					logrus.Fatal(fmt.Sprintf("Cannot overwrite non-directory '%s' with directory '%s'", parentPath, srcPath))
				}
			} else {
				index := strings.LastIndex(parentPath, "/")
				name = parentPath[index+1:]
				parentPath = parentPath[0:index]
				if parent, err := fs.ResourceByPath(parentPath); err != nil {
					if errors.Is(err, core.ErrResourceNotFound) {
						logrus.Fatal("Directory does not exist: " + parentPath)
					}
					logrus.Fatal(err.Error())
				} else {
					parentID = parent.ID
				}
			}

			force, _ := cmd.Flags().GetBool("force")
			if src.Dir {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					logrus.Fatal("Must use -r to copy directories")
				}
			}

			if _, err := fs.Copy(src, uuid.New(), parentID, name, true, force); err != nil {
				logrus.Fatal(err.Error())
			}
		},
	}
	flags := cmd.Flags()
	flags.BoolP("recursive", "r", false, "Recursive (required for directories)")
	flags.BoolP("force", "f", false, "Overwrite without prompting")
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
			var user string
			if _, err := core.Default.UserByEmail(context.Background(), args[0]); err != nil {
				logrus.Fatal(err)
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
					if errors.Is(err, core.ErrResourceNotFound) {
						logrus.Fatal("Resource not found: " + path)
					} else {
						logrus.Fatal(err.Error())
					}
				}
			} else {
				var err error
				if r, err = fs.ResourceByPath(path); err != nil {
					if errors.Is(err, core.ErrResourceNotFound) {
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
	if value, err := cmd.Flags().GetString("user"); err != nil {
		logrus.Fatal(err)
	} else {
		if user, err := core.Default.UserByEmail(context.Background(), value); err != nil {
			logrus.Fatal(err)
		} else {
			fs = core.Default.OpenFileSystem(context.Background(), user)
		}
	}
}

func setupUserFlags(cmd *cobra.Command) {
	flags := cmd.Flags()
	flags.StringP("user", "u", "phylum", "Specify user for resource operations")

}
