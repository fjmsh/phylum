package trash

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupRestoreCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "restore uuid... ",
		Short: "Restore Deleted Resource",
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			for _, uuid := range args {
				r, err := f.ResourceByPathOrUUID(uuid)
				if r.Dir() {
					if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
						fmt.Println("cannot restore '" + uuid + "': Is a directory. Try again with '-r'")
						os.Exit(1)
					}
				}
				p, err := cmd.Flags().GetString("parent")
				r, items, err := r.Restore(p)
				if err != nil {
					fmt.Println("cannot restore '" + uuid + "': " + err.Error())
					os.Exit(1)
				}

				path, err := r.GetPath()
				if err != nil {
					fmt.Println("cannot get path: " + err.Error())
					os.Exit(1)
				}
				if r.Dir() {
					fmt.Printf("Restored dir: %s (%d items)\n", path, items)
				} else {
					fmt.Printf("Restored file: %s\n", path)
				}
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive restore (required for directories)")
	cmd.Flags().StringP("parent", "p", "", "Restore to parent uuid or path")
	return &cmd
}
