package user

import (
	"context"
	"fmt"
	"os"
	"strings"
	"syscall"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

func setupUserAddCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "add username",
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

			f := common.RootFileSystem()
			noCreateHome, _ := cmd.Flags().GetBool("no-create-home")
			homePath := ""
			if !noCreateHome {
				basePath, _ := cmd.Flags().GetString("base-dir")
				if basePath == "" {
					fmt.Println("home directory path not specified. try again with -d or -b")
					os.Exit(1)
				} else {
					homePath = strings.TrimRight(basePath, "/") + "/" + username
				}
			}

			err = db.Get(context.Background()).RunInTx(func(db db.Handler) error {
				userManager := user.ManagerFromDB(db)
				var u user.User
				var home fs.Resource
				if homePath != "" {
					f = common.RootFileSystem().WithDb(db)
					var err error
					home, err = f.CreateResourceByPath(homePath, true, true, fs.ResourceBindConflictResolutionEnsure)
					if err != nil {
						return err
					}
				}

				var homeID pgtype.UUID
				if home.ID() != uuid.Nil {
					homeID = pgtype.UUID{
						Bytes: home.ID(),
						Valid: true,
					}
				}
				if user, err := userManager.CreateUser(username, displayName, password, homeID); err != nil {
					return err
				} else {
					u = user
				}

				if homeID.Valid {
					if _, err := home.UpdatePermissions(u.Username, fs.PermissionRead|fs.PermissionWrite|fs.PermissionShare); err != nil {
						return err
					}
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
	cmd.Flags().StringP("base-dir", "b", "", "Base directory for home")
	cmd.Flags().BoolP("no-create-home", "M", false, "Do not make home directory")
	return cmd
}
