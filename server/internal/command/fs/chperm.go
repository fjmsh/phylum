package fs

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupChpermCommand() *cobra.Command {
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
	return &cmd
}