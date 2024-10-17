package fs

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func formatSize(size int64) string {
	suffix := []string{"", "K", "M", "G", "T"}
	si := 0
	for ; size >= 1000 && si < len(suffix); si, size = si+1, size/1000 {
	}
	return fmt.Sprintf("%4d%s", size, suffix[si])
}

func formatResourceSummary(r core.Resource) string {
	name := r.Name
	if r.Dir {
		name += "/"
	}
	return fmt.Sprintf("%s %s %s %s", r.ID.String(), formatSize(r.ContentSize), name, r.Permissions)
}

func resourceByPathOrUuid(pathOrUuid string) (core.Resource, error) {
	if pathOrUuid[0] == '/' {
		return fs.ResourceByPath(pathOrUuid)
	}
	if id, err := uuid.Parse(pathOrUuid); err != nil {
		return core.Resource{}, err
	} else {
		return fs.ResourceByID(id)
	}

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
			r, err := resourceByPathOrUuid(pathOrUuid)
			if err != nil {
				fmt.Println("cannot access '" + pathOrUuid + "': " + err.Error())
				os.Exit(1)
			}

			fmt.Println("         Name: " + r.Name)
			fmt.Println("           ID: " + r.ID.String())
			fmt.Println("  Permissions: " + r.Permissions)
			fmt.Println("    Inherited: " + r.InheritedPermissions)

			if r.Dir {
				children, err := fs.ReadDir(r)
				if err != nil {
					logrus.Fatal(err)
				}
				fmt.Println()
				fmt.Println("Children:")
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
				// children = sort.Slice(children, func(a core.Resource, b core.Resource) bool {
				// 	return true
				// })
				for _, c := range children {
					fmt.Println(formatResourceSummary(c))
				}
			} else {
				fmt.Printf("         Size: %d\n", r.ContentSize)
				fmt.Println(" Content Type: " + r.ContentType)
				fmt.Println("   SHA256 Sum: " + r.ContentSHA256)
			}
		},
	}
	return &cmd
}
