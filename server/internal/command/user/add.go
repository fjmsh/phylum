package user

import (
	"context"
	"fmt"
	"os"
	"strings"
	"syscall"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

func setupUserAddCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "add email",
		Short: "Add User",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			username := args[0]

			displayName := username
			if n, err := cmd.Flags().GetString("name"); err != nil {
				fmt.Println("invalid value for flag 'name': " + err.Error())
				os.Exit(1)
			} else if n != "" {
				displayName = username
			}

			password, err := cmd.Flags().GetString("password")
			if err != nil {
				fmt.Println("invalid password: " + err.Error())
				os.Exit(1)
			} else if password == "" {
				os.Stdout.WriteString("Password: ")
				bytes, err := term.ReadPassword(syscall.Stdin)
				os.Stdout.WriteString("\n")
				if err != nil {
					fmt.Println("unable to read password: " + err.Error())
					os.Exit(1)
				}
				password = string(bytes)

				os.Stdout.WriteString("Confirm Password: ")
				bytes, err = term.ReadPassword(syscall.Stdin)
				os.Stdout.WriteString("\n")
				if err != nil {
					fmt.Println("unable to read password: " + err.Error())
					os.Exit(1)
				}
				passwordConf := string(bytes)

				if password != passwordConf {
					fmt.Println("password does not match confirmation")
					os.Exit(1)
				}
			}

			rootFS := common.RootFileSystem()
			root := rootFS.RootID()
			if rootPathOrUUID, err := cmd.Flags().GetString("chroot"); err != nil {
				fmt.Println("invalid value for flag 'chroot': " + err.Error())
				os.Exit(2)
			} else if rootPathOrUUID != "" {
				if r, err := rootFS.ResourceByPathOrUUID(rootPathOrUUID); err != nil {
					fmt.Println("invalid value for flag 'chroot': " + err.Error())
					os.Exit(1)
				} else {
					root = r.ID
				}
			}

			createHome, _ := cmd.Flags().GetBool("no-create-home")
			homePath := ""
			if createHome {
				homePath, _ := cmd.Flags().GetString("home-dir")
				if homePath == "" {
					basePath, _ := cmd.Flags().GetString("base-dir")
					if basePath == "" {
						fmt.Println("home directory path not specified. try again with -d or -b")
						os.Exit(1)
					} else {
						homePath = strings.TrimRight(basePath, "/") + "/" + username
					}
				} else {
					homePath = strings.TrimRight(homePath, "/")
				}
			}

			fmt.Println(root)
			fmt.Println(homePath)

			ctx := context.Background()
			err = db.Get().WithTx(ctx, func(db *db.DbHandler) error {
				userManager := user.CreateManager(ctx).WithDb(db)
				var u user.User
				if user, err := userManager.CreateUser(username, displayName, password, root); err != nil {
					return err
				} else {
					u = user
				}

				if homePath != "" {
					rootFS = rootFS.WithDb(db)
					home, err := rootFS.CreateResourceByPath(homePath, true, true)
					if err != nil {
						return err
					}
					if _, err := rootFS.UpdatePermissions(home, u.Username, fs.PermissionReadWriteShare); err != nil {
						return err
					}
					return userManager.UpdateUserHome(u, home.ID)
				}

				return nil
			})
			if err != nil {
				fmt.Println("could not add user: " + err.Error())
				os.Exit(3)
			}
		},
	}
	cmd.Flags().StringP("name", "n", "", "Full Name")
	cmd.Flags().StringP("password", "p", "", "Password")
	cmd.Flags().StringP("chroot", "R", "", "Chroot")
	cmd.Flags().StringP("base-dir", "b", "/home", "Base directory for home")
	cmd.Flags().StringP("home-dir", "d", "", "Home directory")
	cmd.Flags().BoolP("no-create-home", "M", false, "Do not make home directory")
	return cmd
}
