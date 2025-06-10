package trash

import (
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/spf13/cobra"
)

func setupListCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "list",
		Short: "List Trashed Resources",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			n, _ := cmd.Flags().GetUint("num")
			cursor, _ := cmd.Flags().GetString("cursor")
			deleted, cursor, err := f.TrashList(cursor, n)
			if err != nil {
				fmt.Println("cannot list trash: " + err.Error())
				os.Exit(1)
			}

			for _, c := range deleted {
				fmt.Println(common.FormatResourceSummary(c, "", pgtype.Timestamp{}))
			}
			if cursor != "" {
				fmt.Println("Cursor: " + cursor)
			}
		},
	}
	cmd.Flags().UintP("num", "n", 5, "How many items to show")
	cmd.Flags().StringP("cursor", "P", "", "Pagination Cursor")
	return &cmd
}
