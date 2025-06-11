package fs

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

func setupInfoCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:     "info <path>",
		Aliases: []string{"ls"},
		Short:   "Print Resource Details",
		Long: `Prints all relevant details about a resource.

Columns for children:
ID
Permission Grants ('+' if more than 9)
Public Shares ('+' if more than 9)
Version History ('+' if more than 9, '-' if directory)
Size ('-' if directory)
SHA-256 ('-' if directory)
Deleted ('*' if deleted, blank otherwise)
Name
		
NOTE: You may use '<id>:<path>' as the path to refer to the resource at a
path relative to a root resource with the given ID, or simply '<id>:' to refer
to the resource with a particular ID.`,

		Args: cobra.ExactArgs(1),
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
			fmt.Println("       ID: " + r.ID().String())
			fmt.Println("   Parent: " + r.VisibleParentID().String())
			fmt.Println("     Path: " + path)
			fmt.Println("  Created: " + r.Created().Local().Format(time.RFC1123))
			fmt.Println(" Modified: " + r.Modified().Local().Format(time.RFC1123))
			if r.Deleted().Valid {
				fmt.Println(" Deleted:  " + r.Deleted().Time.Local().Format(time.RFC1123))
			}
			fmt.Println()

			fmt.Println("Inherited: " + formatPermissionsJson(r.InheritedPermissions()))
			fmt.Println("  Granted: " + formatGrantsJson(r.Grants()))
			fmt.Println()

			if r.Dir() {
				fmt.Println(" Children:")
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
			} else {
				fmt.Println("     Size: " + common.FormatSize(int(r.LatestVersion().Size)))
				fmt.Println("  SHA-256: " + r.LatestVersion().SHA256[0:12])
				versions, err := f.GetAllVersions(r)
				if err != nil {
					fmt.Println(err.Error())
					os.Exit(1)
				}
				fmt.Println(" Versions: " + strconv.Itoa(len(versions)))
				if v, _ := cmd.Flags().GetBool("show-versions"); v {
					fmt.Println()
					for i, v := range versions {
						extra := ""
						if i == 0 {
							extra += " [current]"
						}
						if v.Deleted != 0 {
							extra += " [deleted]"
						}
						fmt.Printf("%s %5s %s %s%s\n", v.ID.String(), common.FormatSize(int(v.Size)), v.SHA256[0:12], time.Unix(int64(v.Created), 0).Local().Format(time.RFC1123), extra)
					}
				}
			}
		},
	}
	cmd.Flags().BoolP("include-deleted", "x", false, "Include deleted files")
	cmd.Flags().BoolP("show-versions", "v", false, "Show previous versions")
	return &cmd
}

func formatPermissionsJson(j []byte) string {
	p := make(map[string]core.Permission)
	json.Unmarshal(j, &p)
	if len(p) == 0 {
		return "None"
	}
	perm := make([]string, 0, len(p))
	for k, v := range p {
		perm = append(perm, getUserEmail(k)+"("+formatPermission(v)+")")
	}
	return strings.Join(perm, ", ")
}

func formatGrantsJson(j []byte) string {
	g := make(map[string]grant)
	json.Unmarshal(j, &g)
	if len(g) == 0 {
		return "None"
	}
	perm := make([]string, 0, len(g))
	for k, v := range g {
		perm = append(perm, getUserEmail(k)+"("+formatPermission(v.Permission)+")")
	}
	return strings.Join(perm, ", ")
}

type grant struct {
	Permission core.Permission `json:"p"`
	Timestamp  int             `json:"t"`
}

func getUserEmail(s string) string {
	if id, err := strconv.Atoi(s); err != nil {
		return "[user " + s + "]"
	} else if email, err := core.UserEmailByID(db.Get(context.Background()), id); err != nil {
		return "[user " + s + "]"
	} else {
		return email
	}

}

func formatPermission(p core.Permission) string {
	if p == core.PermissionSU {
		return "su"
	}
	str := ""
	if p&core.PermissionRead != 0 {
		p -= core.PermissionRead
		str += "r"
	}
	if p&core.PermissionWrite != 0 {
		p -= core.PermissionWrite
		str += "w"
	}
	if p&core.PermissionShare != 0 {
		p -= core.PermissionShare
		str += "s"
	}
	if p != 0 {
		str += fmt.Sprintf("u(%d)", p)
	}
	return str
}
