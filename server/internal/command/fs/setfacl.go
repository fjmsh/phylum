package fs

import (
	"context"
	"errors"
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
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
			r, err := f.ResourceByPath(path)
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
			if user, err := core.UserByEmail(db.Get(context.Background()), email); err != nil {
				fmt.Println("cannot update permissions for user '" + email + "': " + err.Error())
				os.Exit(1)
			} else {
				if _, err := f.UpdatePermissions(r, user, permission); err != nil {
					fmt.Println("cannot update permissions for '" + path + "': " + err.Error())
					os.Exit(1)
				}
				go func() {
					mail.SendResourceShareEmail(user, r)
				}()
			}

		},
	}
	return &cmd
}

func parsePermissionString(s string) (core.ResourcePermission, error) {
	switch s {
	case "none":
		return core.ResourcePermissionNone, nil
	case "read":
		return core.ResourcePermissionRead, nil
	case "write":
		return core.ResourcePermissionRead | core.ResourcePermissionWrite, nil
	case "share":
		return core.ResourcePermissionRead | core.ResourcePermissionWrite | core.ResourcePermissionShare, nil
	}
	return core.ResourcePermissionNone, errors.New("unrecognized permission: " + s)
}
