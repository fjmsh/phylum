package fs

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupRmCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "rm {path | uuid}",
		Short: "Delete Resource",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			pathOrUUID := args[0]
			r, err := f.ResourceByPathOrUUID(pathOrUUID)
			if err != nil {
				fmt.Println("cannot remove '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}

			if r.Dir() {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					fmt.Println("cannot remove '" + pathOrUUID + "': Is a directory. Try again with '-r'")
					os.Exit(1)
				}
			}

			hard, _ := cmd.Flags().GetBool("hard")
			_, err = r.DeleteRecursive(!hard)
			if err != nil {
				fmt.Println("cannot remove '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")
	cmd.Flags().BoolP("hard", "x", false, "Permanently delete (do not send to trash)")

	return &cmd
}
