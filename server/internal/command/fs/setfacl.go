package fs

import (
	"context"
	"errors"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

func setupSetfaclCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "setfacl <path> <user-email> (none|read|write|share)",
		Short: "Access Control",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			path := args[0]
			r, err := f.ResourceByPathWithRoot(path)
			if err != nil {
				fmt.Println("cannot update permissions for '" + path + "': " + err.Error())
				os.Exit(1)
			}
			permission, err := parsePermissionString(args[2])
			if err != nil {
				fmt.Println("cannot update permissions for '" + path + "': " + err.Error())
				os.Exit(1)
			}

			email := args[1]
			if user, err := user.ManagerFromContext(context.Background()).UserByEmail(email); err != nil {
				fmt.Println("cannot update permissions for user '" + email + "': " + err.Error())
				os.Exit(1)
			} else {
				if _, err := f.UpdatePermissions(r, user.ID, permission); err != nil {
					fmt.Println("cannot update permissions for '" + path + "': " + err.Error())
					os.Exit(1)
				}
			}

		},
	}
	return &cmd
}

func parsePermissionString(s string) (core.Permission, error) {
	switch s {
	case "none":
		return core.PermissionNone, nil
	case "read":
		return core.PermissionRead, nil
	case "write":
		return core.PermissionRead | core.PermissionWrite, nil
	case "share":
		return core.PermissionRead | core.PermissionWrite | core.PermissionShare, nil
	}
	return core.PermissionNone, errors.New("unrecognized permission: " + s)
}
