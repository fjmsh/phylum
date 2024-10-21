package fs

import (
	"context"
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

			permission := fs.PermissionNone
			switch args[2] {
			case "none":
			case "read":
				permission = fs.PermissionReadOnly
			case "write":
				permission = fs.PermissionReadWrite
			case "share":
				permission = fs.PermissionReadWriteShare
			default:
				fmt.Println("cannot update permissions for '" + pathOrUUID + "': unrecognized permission: " + args[2])
				os.Exit(1)
			}

			if _, err := f.UpdatePermissions(r, username, permission); err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	return &cmd
}
