package fs

import (
	"encoding/json"
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

			path, err := r.GetPath()
			if err != nil {
				fmt.Println("cannot get path:" + err.Error())
				os.Exit(1)
			}
			fmt.Println(path)
			fmt.Println(permissionsJsonString(r.Permissions()))
			fmt.Println(formatRow(r.ID().String(), formatSize(r.ContentLength()), r.ContentSHA256(), ".", grantsJsonString(r.Grants())))

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
	return fmt.Sprintf("%s %4s %s %-24s %s", id, size, sha256[0:8], name, permissions)
}

func formatResourceSummary(r fs.Resource) string {
	name := r.Name()
	if r.Dir() {
		name += "/"
	}
	return formatRow(r.ID().String(), formatSize(r.ContentLength()), r.ContentSHA256(), name, grantsJsonString(r.Grants()))
}

func permissionsJsonString(j []byte) string {
	p := make(map[string]fs.Permission)
	json.Unmarshal(j, &p)
	if len(p) == 0 {
		return ""
	}
	perm := make([]string, 0, len(p))
	for k, v := range p {
		perm = append(perm, k+": "+permissionString(v))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}
func grantsJsonString(j []byte) string {
	p := make(map[string]interface{})
	json.Unmarshal(j, &p)
	if len(p) == 0 {
		return ""
	}
	perm := make([]string, 0, len(p))
	for k, v := range p {
		perm = append(perm, k+": "+permissionString(int32((v.(map[string]interface{})["p"]).(float64))))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}

func permissionString(p fs.Permission) string {
	if p == fs.PermissionSU {
		return "su"
	}
	str := ""
	if p&fs.PermissionRead != 0 {
		p -= fs.PermissionRead
		str += "r"
	}
	if p&fs.PermissionWrite != 0 {
		p -= fs.PermissionWrite
		str += "w"
	}
	if p&fs.PermissionShare != 0 {
		p -= fs.PermissionShare
		str += "s"
	}
	if p != 0 {
		str += fmt.Sprintf("u(%d)", p)
	}
	return str
}
