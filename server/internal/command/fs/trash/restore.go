package trash

import (
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

func setupRestoreCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "restore uuid... ",
		Short: "Restore Deleted Resource",
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
					fmt.Println("cannot restore'" + id.String() + "': " + err.Error())
					os.Exit(1)
				}
				if r.Dir() {
					if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
						fmt.Println("cannot restore '" + id.String() + "': Is a directory. Try again with '-r'")
						os.Exit(1)
					}
				}
				p, _ := cmd.Flags().GetString("parent")
				name, _ := cmd.Flags().GetString("name")
				autoRename, _ := cmd.Flags().GetBool("auto-rename")
				r, err = f.RestoreDeleted(r, p, name, autoRename)
				if err != nil {
					fmt.Println("cannot restore '" + id.String() + "': " + err.Error())
					os.Exit(1)
				}

				path, err := f.GetPath(r)
				if err != nil {
					fmt.Println("cannot get path: " + err.Error())
					os.Exit(1)
				}
				fmt.Println("Restored " + path)
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive restore (required for directories)")
	cmd.Flags().StringP("parent", "p", "", "Restore to parent uuid or path")
	cmd.Flags().StringP("name", "n", "", "Overwrite name")
	cmd.Flags().BoolP("auto-rename", "a", false, "Automatically rename on name conflict")
	return &cmd
}
