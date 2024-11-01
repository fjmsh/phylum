package user

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/user"
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
			if bookmarks, err := user.CreateManager(context.Background()).Bookmarks(common.User(cmd)); err != nil {
				fmt.Println("unable to list bookmark: " + err.Error())
				os.Exit(1)
			} else {
				for _, b := range bookmarks {
					fmt.Printf("%s %s %s\n", b.ID().String(), b.Name(), b.PermissionsString())
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
			r, err := common.UserFileSystem(cmd).ResourceByPathOrUUID(args[0])
			if err != nil {
				fmt.Println("unable to remove bookmark: " + err.Error())
				os.Exit(1)
			}

			if err := user.CreateManager(context.Background()).RemoveBookmark(common.User(cmd), r.ID()); err != nil {
				fmt.Println("unable to remove bookmark: " + err.Error())
				os.Exit(1)
			}
		},
	}
	return cmd
}

func setupBookmarksAddCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "add [<path>|<uuid>]",
		Short: "Add Bookmark",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			r, err := common.UserFileSystem(cmd).ResourceByPathOrUUID(args[0])
			if err != nil {
				fmt.Println("unable to add bookmark: " + err.Error())
				os.Exit(1)
			}

			if err := user.CreateManager(context.Background()).AddBookmark(common.User(cmd), r); err != nil {
				fmt.Println("unable to add bookmark: " + err.Error())
				os.Exit(1)
			}
		},
	}
	return cmd
}
