package trash

import (
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

func setupDeleteCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "delete uuid",
		Short: "Permanently delete resource from trash",
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			for _, idStr := range args {
				id, err := uuid.Parse(idStr)
				if err != nil {
					fmt.Println("cannot remove '" + idStr + "': " + err.Error())
					os.Exit(1)
				}
				r, err := f.ResourceByID(id)
				if err != nil {
					fmt.Println("cannot remove '" + id.String() + "': " + err.Error())
					os.Exit(1)
				}

				if r.Dir() {
					if recursive, _ := cmd.Flags().GetBool("recursive"); !recursive {
						fmt.Println("cannot remove '" + id.String() + "': Is a directory. Try again with '-r'")
						os.Exit(1)
					}
				}

				if err := f.DeleteForever(r); err != nil {
					fmt.Println("cannot remove '" + id.String() + "': " + err.Error())
					os.Exit(1)
				}

			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")

	return &cmd
}
