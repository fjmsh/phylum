package fs

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/spf13/cobra"
)

func formatSize(size int64) string {
	suffix := []string{"", "K", "M", "G", "T"}
	si := 0
	for ; size >= 1000 && si < len(suffix); si, size = si+1, size/1000 {
	}
	return fmt.Sprintf("%d%s", size, suffix[si])
}

func formatRow(id, size, sha256, name, permissions string) string {
	if sha256 == "" {
		sha256 = "dir     "
	}
	return fmt.Sprintf("%s %5s %s %-24s %s", id, size, sha256[0:8], name, permissions)
}

func formatResourceSummary(r core.Resource) string {
	name := r.Name
	if r.Dir {
		name += "/"
	}
	return formatRow(r.ID.String(), formatSize(r.ContentSize), r.ContentSHA256, name, r.Permissions)
}

func setupLsCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "ls <path | uuid>",
		Short: "List Resource Details",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			pathOrUuid := args[0]
			r, err := fs.ResourceByPathOrUuid(pathOrUuid)
			if err != nil {
				fmt.Println("cannot access '" + pathOrUuid + "': " + err.Error())
				os.Exit(1)
			}

			fmt.Println(formatRow(r.ParentID.String(), formatSize(0), "", "..", r.InheritedPermissions))
			fmt.Println(formatRow(r.ID.String(), formatSize(0), r.ContentSHA256, ".("+r.Name+")", r.Permissions))

			if r.Dir {
				children, err := fs.ReadDir(r)
				if err != nil {
					fmt.Println("cannot access '" + pathOrUuid + "': " + err.Error())
					os.Exit(1)
				}
				sort.Slice(children, func(i, j int) bool {
					a := children[i]
					b := children[j]
					if a.Dir != b.Dir {
						if a.Dir {
							return true
						}
					}
					return strings.Compare(strings.ToLower(a.Name), strings.ToLower((b.Name))) <= 0
				})
				for _, c := range children {
					fmt.Println(formatResourceSummary(c))
				}
			}
		},
	}
	return &cmd
}
