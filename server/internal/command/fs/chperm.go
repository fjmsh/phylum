package fs

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/util"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func setupChpermCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "chperm <path | uuid> <user> [ none | read | write | share ]",
		Short: "Change Permissions",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			f, err := util.OpenFileSystemFromFlags(cmd)
			if err != nil {
				fmt.Println("could not open filesystem: " + err.Error())
				os.Exit(1)
			}
			pathOrUuid := args[0]
			r, err := f.ResourceByPathOrUuid(pathOrUuid)
			if err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUuid + "': " + err.Error())
				os.Exit(1)
			}

			user := args[1]
			if _, err := app.Default.UserByEmail(context.Background(), user); err != nil {
				fmt.Println("cannot update permissions for user '" + user + "': " + err.Error())
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
				fmt.Println("cannot update permissions for '" + pathOrUuid + "': unrecognized permission: " + args[2])
				os.Exit(1)
			}

			if err := f.UpdatePermissions(r, user, permission); err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUuid + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	return &cmd
}
