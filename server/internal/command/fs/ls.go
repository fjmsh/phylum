package fs

import (
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupLsCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "ls <path>",
		Short: "List Resource Details",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			pathOrUUID := args[0]
			r, err := f.ResourceByPathWithRoot(pathOrUUID)
			if err != nil {
				fmt.Println("unable to find '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}

			path, err := f.GetPath(r)
			if err != nil {
				fmt.Println("cannot get path:" + err.Error())
				os.Exit(1)
			}
			fmt.Println("ID: " + r.ID().String())
			fmt.Println("Path: " + path)
			fmt.Println("Created:  " + r.Created().Local().Format(time.RFC1123))
			fmt.Println("Modified: " + r.Modified().Local().Format(time.RFC1123))
			if r.Deleted().Valid {
				fmt.Println("Deleted:  " + r.Deleted().Time.Local().Format(time.RFC1123))
			}
			fmt.Println()

			fmt.Println("Inherited Permissions: " + common.FormatPermissionsJson(r.InheritedPermissions()))
			grants := common.FormatGrantsJson(r.Grants())
			if grants == "" {
				grants = "None"
			}
			fmt.Println("Permission Grants: " + grants)

			fmt.Println()
			// fmt.Println(common.FormatResourceSummary(r, ".", pgtype.Timestamp{}))

			if r.Dir() {
				fmt.Println("Children:")
				includeDeleted, _ := cmd.Flags().GetBool("include-deleted")
				children, err := f.ReadDirDeleted(r, false, includeDeleted)
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
					fmt.Println(common.FormatResourceSummary(c, "", r.Deleted()))
				}
			}
		},
	}
	cmd.Flags().BoolP("include-deleted", "x", false, "Include deleted files")
	return &cmd
}
