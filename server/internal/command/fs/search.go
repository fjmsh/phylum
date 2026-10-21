package fs

import (
	"fmt"
	"os"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/spf13/cobra"
)

func setupSearchCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "search <terms>",
		Short: "Search Resources",
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			query := strings.Join(args, " ")
			includeDeleted, _ := cmd.Flags().GetBool("include-deleted")
			var res []core.Resource
			if root, err := cmd.Flags().GetString("root"); root == "" {
				res, err = f.Search(query, includeDeleted)
				if err != nil {
					fmt.Println("cannot search: " + err.Error())
					os.Exit(1)
				}
			} else if r, err := f.ResourceByPathWithRoot(root); err != nil {
				fmt.Printf("unable to locate search root '%s': %s", root, err.Error())
				os.Exit(1)
			} else {
				res, err = f.SearchWithRoot(r, query, includeDeleted)
				if err != nil {
					fmt.Println("cannot search: " + err.Error())
					os.Exit(1)
				}
			}

			for _, c := range res {
				fmt.Println(common.FormatResourceSummary(c, "", pgtype.Timestamp{}))
			}
		},
	}
	cmd.Flags().BoolP("include-deleted", "x", false, "Include Deleted Files")
	cmd.Flags().String("root", "", "Search Root")
	return &cmd
}
