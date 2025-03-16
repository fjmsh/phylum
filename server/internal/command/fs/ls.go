package fs

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func setupLsCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "ls {path | uuid}",
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

			path, err := r.GetPath()
			if err != nil {
				fmt.Println("cannot get path:" + err.Error())
				os.Exit(1)
			}
			fmt.Println(path)
			fmt.Println(formatPermissionsJson(r.Permissions()))
			if r.Deleted() != nil {
				fmt.Println("Deleted on " + r.Deleted().Local().Format(time.RFC1123))
			}
			fmt.Println()
			fmt.Println(common.FormatResourceSummaryWithName(r, "."))

			if r.Dir() {
				children, err := r.ReadDir(false)
				if err != nil {
					fmt.Println("cannot access '" + pathOrUUID + "': " + err.Error())
					os.Exit(1)
				}
				sort.Slice(children, func(i, j int) bool {
					a := children[i]
					b := children[j]
					if a.Dir() != b.Dir() {
						if a.Dir() {
							return true
						}
					}
					return strings.Compare(strings.ToLower(a.Name()), strings.ToLower((b.Name()))) <= 0
				})
				for _, c := range children {
					fmt.Println(common.FormatResourceSummary(c.(fs.Resource)))
				}
			}
		},
	}
	return &cmd
}

func formatPermissionsJson(j []byte) string {
	p := make(map[string]fs.Permission)
	json.Unmarshal(j, &p)
	if len(p) == 0 {
		return ""
	}
	perm := make([]string, 0, len(p))
	for k, v := range p {
		perm = append(perm, k+": "+common.FormatPermission(v))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}
