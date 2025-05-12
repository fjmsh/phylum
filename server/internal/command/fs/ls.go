package fs

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
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

			path, err := r.GetPath()
			if err != nil {
				fmt.Println("cannot get path:" + err.Error())
				os.Exit(1)
			}
			fmt.Println(path)
			fmt.Println("Created:  " + r.Created().Local().Format(time.RFC1123))
			fmt.Println("Modified: " + r.Modified().Local().Format(time.RFC1123))
			if r.Deleted().Valid {
				fmt.Println("Deleted:  " + r.Deleted().Time.Local().Format(time.RFC1123))
			}
			fmt.Println("Inherited Permissions: " + formatPermissionsJson(r.InheritedPermissions()))
			fmt.Println("Permission Grants: " + formatGrantsJson(r.Grants()))
			fmt.Println()
			fmt.Println(common.FormatResourceSummary(r, ".", pgtype.Timestamp{}))

			if r.Dir() {
				includeDeleted, _ := cmd.Flags().GetBool("include-deleted")
				children, err := r.ReadDirDeleted(false, includeDeleted)
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

type Grant struct {
	Permission fs.Permission `json:"p"`
	Timestamp  int           `json:"t"`
}

func formatGrantsJson(j []byte) string {
	g := make(map[string]Grant)
	json.Unmarshal(j, &g)
	if len(g) == 0 {
		return ""
	}
	perm := make([]string, 0, len(g))
	for k, v := range g {
		perm = append(perm, k+": "+common.FormatPermission(v.Permission))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}
