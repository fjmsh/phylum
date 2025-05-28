package user

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

func setupGrantCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "grant <email> <permission-hex>",
		Short: "Grant Permissions",
		Run: func(cmd *cobra.Command, args []string) {
			userManager := user.ManagerFromContext(context.Background())
			u, err := userManager.UserByEmail(args[0])
			if err != nil {
				fmt.Println("unable to find user :" + err.Error())
				os.Exit(1)
			}
			var p user.Permissions
			_, err = fmt.Sscanf(args[1], "0x%x", &p)
			if err != nil {
				fmt.Println("permissions must be of the format 0x<hex>")
				os.Exit(1)
			}

			userManager.GrantUserPermissions(u, p)
			if err != nil {
				fmt.Println("unable to update permissions:" + err.Error())
				os.Exit(1)
			}
		},
	}
}

func setupRevokeCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "revoke <email> <permission-hex>",
		Short: "Revoke Permissions",
		Run: func(cmd *cobra.Command, args []string) {
			userManager := user.ManagerFromContext(context.Background())
			u, err := userManager.UserByEmail(args[0])
			if err != nil {
				fmt.Println("unable to find user :" + err.Error())
				os.Exit(1)
			}
			var p user.Permissions
			_, err = fmt.Sscanf(args[1], "0x%x", &p)
			if err != nil {
				fmt.Println("permissions must be of the format 0x<hex>")
				os.Exit(1)
			}

			userManager.RevokeUserPermissions(u, p)
			if err != nil {
				fmt.Println("unable to update permissions:" + err.Error())
				os.Exit(1)
			}
		},
	}
}
