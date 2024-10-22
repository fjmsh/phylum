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
	cmd.AddCommand(setupBookmarksAddCommand())

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

			user.CreateManager(context.Background()).AddBookmark(common.User(cmd), r.ID)
			common.User(cmd)
		},
	}
	return cmd
}
