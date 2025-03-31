package fs

import (
	"fmt"
	"os"
	"strings"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupSearchCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "search",
		Short: "Search Resources",
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			query := strings.Join(args, " ")
			res, err := f.Search(query)
			if err != nil {
				fmt.Println("cannot search: " + err.Error())
				os.Exit(1)
			}

			for _, c := range res {
				fmt.Println(common.FormatResourceSummary(c, "", nil))
			}
		},
	}
	return &cmd
}
