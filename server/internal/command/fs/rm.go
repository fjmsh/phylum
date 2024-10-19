package fs

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/util"
	"github.com/spf13/cobra"
)

func setupRmCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "rm <path | uuid>",
		Short: "Delete Resource",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f, err := util.OpenFileSystemFromFlags(cmd)
			if err != nil {
				fmt.Println("could not open filesystem: " + err.Error())
				os.Exit(1)
			}

			pathOrUuid := args[0]
			r, err := f.ResourceByPathOrUuid(pathOrUuid)
			if err != nil {
				fmt.Println("cannot remove '" + pathOrUuid + "': " + err.Error())
				os.Exit(1)
			}

			if r.Dir {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					fmt.Println("cannot remove '" + pathOrUuid + "': Is a directory. Try again with '-r'")
					os.Exit(1)
				}
			}

			f.DeleteRecursive(r, true)
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")

	return &cmd
}
