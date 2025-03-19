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
				if err != nil {
					fmt.Println("cannot restore'" + uuid + "': " + err.Error())
					os.Exit(1)
				}
				if r.Dir() {
					if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
						fmt.Println("cannot restore '" + uuid + "': Is a directory. Try again with '-r'")
						os.Exit(1)
					}
				}
				p, _ := cmd.Flags().GetString("parent")
				name, _ := cmd.Flags().GetString("name")
				autoRename, _ := cmd.Flags().GetBool("auto-rename")
				r, items, size, err := r.Restore(p, name, autoRename)
				if err != nil {
					fmt.Println("cannot restore '" + uuid + "': " + err.Error())
					os.Exit(1)
				}

				path, err := r.GetPath()
				if err != nil {
					fmt.Println("cannot get path: " + err.Error())
					os.Exit(1)
				}
				fmt.Printf("Restored %s (%d items, %s)\n", path, items, common.FormatSize(int(size)))
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive restore (required for directories)")
	cmd.Flags().StringP("parent", "p", "", "Restore to parent uuid or path")
	cmd.Flags().StringP("name", "n", "", "Overwrite name")
	cmd.Flags().BoolP("auto-rename", "a", false, "Automatically rename on name conflict")
	return &cmd
}
