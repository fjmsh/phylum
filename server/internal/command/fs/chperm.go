package fs

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/spf13/cobra"
)

func setupChpermCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "chperm <path | uuid> <user> [ none | read | write | share ]",
		Short: "Change Permissions",
		Args:  cobra.ExactArgs(3),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			pathOrUuid := args[0]
			r, err := resourceByPathOrUuid(pathOrUuid)
			if err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUuid + "': " + err.Error())
				os.Exit(1)
			}

			user := args[1]
			if _, err := core.Default.UserByEmail(context.Background(), user); err != nil {
				fmt.Println("cannot update permissions for user '" + user + "': " + err.Error())
				os.Exit(1)
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
				fmt.Println("cannot update permissions for '" + pathOrUuid + "': unrecognized permission: " + args[2])
				os.Exit(1)
			}

			if err := fs.UpdatePermissions(r, user, permission); err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUuid + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	return &cmd
}
