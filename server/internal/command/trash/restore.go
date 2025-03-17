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
				p, err := cmd.Flags().GetString("parent")
				_, items, err := r.Restore(p)
				if err != nil {
					fmt.Println("cannot restore '" + uuid + "': " + err.Error())
					os.Exit(1)
				}

				fmt.Printf("Items restored: %d\n", items)
			}
		},
	}
	cmd.Flags().StringP("parent", "p", "", "Restore to parent uuid or path")
	return &cmd
}
