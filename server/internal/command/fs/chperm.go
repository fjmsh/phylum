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

			permission, err := fs.ParsePermissionString(args[2])
			if err != nil {
				fmt.Println("cannot update permissions for '" + pathOrUUID + "': " + err.Error())
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
