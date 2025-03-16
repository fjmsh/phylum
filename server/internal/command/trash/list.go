package trash

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupListCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "list",
		Short: "List Trashed Resources",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			n, _ := cmd.Flags().GetInt("num")
			cursor, _ := cmd.Flags().GetString("cursor")
			deleted, cursor, err := f.ListDeleted(cursor, n)
			if err != nil {
				fmt.Println("cannot list trash: " + err.Error())
				os.Exit(1)
			}

			for _, c := range deleted {
				fmt.Println(common.FormatResourceSummary(c))
			}
			if cursor != "" {
				fmt.Println("Cursor: " + cursor)
			}
		},
	}
	cmd.Flags().IntP("num", "n", 5, "How many items to show")
	cmd.Flags().StringP("cursor", "c", "", "Pagination Cursor")
	return &cmd
}
