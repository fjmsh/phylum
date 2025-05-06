package user

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupBookmarksCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "bookmarks",
		Short: "Manage User Bookmarks",
	}

	cmd.PersistentFlags().StringP("user", "u", "", "User")
	cmd.AddCommand(
		setupBookmarksListCommand(),
		setupBookmarksAddCommand(),
		setupBookmarksRemoveCommand(),
	)

	return cmd
}

func setupBookmarksListCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "list",
		Short: "List Bookmarks",
		Args:  cobra.ExactArgs(0),
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				logrus.Fatal("unable to list bookmarks: user not specified")
			}
			if bookmarks, err := user.ManagerFromContext(context.Background()).ListBookmarks(*u); err != nil {
				fmt.Println("unable to list bookmark: " + err.Error())
				os.Exit(1)
			} else {
				for _, b := range bookmarks {
					fmt.Printf("%s %s\n", b.ResourceID.String(), b.Name)
				}
			}
		},
	}
	return cmd
}

func setupBookmarksRemoveCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "remove [<path>|<uuid>]",
		Short: "Remove Bookmark",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				logrus.Fatal("unable to remove bookmark: user not specified")
			}

			r, err := common.UserFileSystem(cmd).ResourceByPathOrUUID(args[0])
			if err != nil {
				fmt.Println("unable to remove bookmark: " + err.Error())
				os.Exit(1)
			}

			if err := user.ManagerFromContext(context.Background()).RemoveBookmark(*u, r.ID()); err != nil {
				fmt.Println("unable to remove bookmark: " + err.Error())
				os.Exit(1)
			}
		},
	}
	return cmd
}

func setupBookmarksAddCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "add (path | uuid) [name]",
		Short: "Add Bookmark",
		Args:  cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				logrus.Fatal("unable to add bookmark: user not specified")
			}
			r, err := common.UserFileSystem(cmd).ResourceByPathOrUUID(args[0])
			if err != nil {
				fmt.Println("unable to add bookmark: " + err.Error())
				os.Exit(1)
			}
			name := ""
			if len(args) == 2 {
				name = args[1]
			}

			if _, err := user.ManagerFromContext(context.Background()).AddBookmark(*u, r, name); err != nil {
				fmt.Println("unable to add bookmark: " + err.Error())
				os.Exit(1)
			}
		},
	}
	return cmd
}
