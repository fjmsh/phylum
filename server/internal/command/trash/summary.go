package trash

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupSummaryCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "summary",
		Short: "List Trash Summary",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			items, size, err := f.TrashSummary()
			if err != nil {
				fmt.Println("cannot get trash summary: " + err.Error())
				os.Exit(1)
			}

			fmt.Printf("Items in trash: %d\n", items)
			fmt.Printf("Space occupied: %s\n", common.FormatSize(size))
		},
	}
	return &cmd
}
