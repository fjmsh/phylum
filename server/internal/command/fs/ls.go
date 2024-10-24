package fs

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func setupLsCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "ls <path | uuid>",
		Short: "List Resource Details",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			pathOrUUID := args[0]
			r, err := f.ResourceByPathOrUUID(pathOrUUID)
			if err != nil {
				fmt.Println("cannot access '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}

			fmt.Println(r.Path + " " + r.InheritedPermissionsString())
			fmt.Println(formatRow(r.ID.String(), formatSize(r.ContentSize), r.ContentSHA256, ".", r.PermissionsString()))

			if r.Dir {
				children, err := f.ReadDir(r, false)
				if err != nil {
					fmt.Println("cannot access '" + pathOrUUID + "': " + err.Error())
					os.Exit(1)
				}
				sort.Slice(children, func(i, j int) bool {
					a := children[i]
					b := children[j]
					if a.FSDir() != b.FSDir() {
						if a.FSDir() {
							return true
						}
					}
					return strings.Compare(strings.ToLower(a.FSName()), strings.ToLower((b.FSName()))) <= 0
				})
				for _, c := range children {
					fmt.Println(formatResourceSummary(c.(fs.Resource)))
				}
			}
		},
	}
	return &cmd
}

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

func formatResourceSummary(r fs.Resource) string {
	name := r.Name
	if r.Dir {
		name += "/"
	}
	return formatRow(r.ID.String(), formatSize(r.ContentSize), r.ContentSHA256, name, r.PermissionsString())
}
