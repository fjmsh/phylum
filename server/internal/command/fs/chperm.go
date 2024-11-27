package fs

import (
	"context"
	"errors"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

func setupChpermCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "chperm <path | uuid> <user> [ none | read | write | share ]",
		Short: "Change Permissions",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			pathOrUUID := args[0]
			r, err := f.ResourceByPathOrUUID(pathOrUUID)
			if err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}

			username := args[1]
			if _, err := user.CreateManager(context.Background()).UserByEmail(username); err != nil {
				fmt.Println("cannot update permissions for user '" + username + "': " + err.Error())
				os.Exit(1)
			}

			permission, err := parsePermissionString(args[2])
			if err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}

			if _, err := r.UpdatePermissions(username, permission); err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	return &cmd
}

func parsePermissionString(s string) (fs.Permission, error) {
	switch s {
	case "none":
		return fs.PermissionNone, nil
	case "read":
		return fs.PermissionRead, nil
	case "write":
		return fs.PermissionRead | fs.PermissionWrite, nil
	case "share":
		return fs.PermissionRead | fs.PermissionWrite | fs.PermissionShare, nil
	}
	return fs.PermissionNone, errors.New("unrecognized permission: " + s)
}
