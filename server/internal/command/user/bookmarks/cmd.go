package bookmarks

import (
	"context"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "bookmarks",
		Short: "Manage Bookmarks",
	}

	cmd.AddCommand(
		setupListCommand(),
		setupAddCommand(),
		setupRemoveCommand(),
	)

	return cmd
}

func setupListCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "list",
		Short: "List Bookmarks",
		Args:  cobra.ExactArgs(0),
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				fmt.Println("unable to list bookmarks: user not specified")
				os.Exit(1)
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

func setupRemoveCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "remove <path>",
		Short: "Remove Bookmark",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				fmt.Println("unable to remove bookmark: user not specified")
				os.Exit(1)
			}

			r, err := common.UserFileSystem(cmd).ResourceByPathWithRoot(args[0])
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

func setupAddCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "add (path | uuid) [name]",
		Short: "Add Bookmark",
		Args:  cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				fmt.Println("unable to add bookmark: user not specified")
				os.Exit(1)
			}
			r, err := common.UserFileSystem(cmd).ResourceByPathWithRoot(args[0])
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
