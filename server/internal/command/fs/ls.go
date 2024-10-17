package fs

import (
	"errors"
	"fmt"
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

func setupLsCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "ls <path | uuid>",
		Short: "List Resource Details",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			var r core.Resource
			if path[0] != '/' {
				var id uuid.UUID
				var err error
				if id, err = uuid.Parse(path); err != nil {
					logrus.Fatal(err)
				}

				if r, err = fs.ResourceByID(id); err != nil {
					if errors.Is(err, core.ErrResourceNotFound) {
						logrus.Fatal("Resource not found: " + path)
					} else {
						logrus.Fatal(err.Error())
					}
				}
			} else {
				var err error
				if r, err = fs.ResourceByPath(path); err != nil {
					if errors.Is(err, core.ErrResourceNotFound) {
						logrus.Fatal("Resource not found: " + path)
					} else {
						logrus.Fatal(err.Error())
					}
				}
			}

			logrus.Info("         Name: " + r.Name)
			logrus.Info("           ID: " + r.ID.String())
			logrus.Info("  Permissions: " + r.Permissions)
			logrus.Info("    Inherited: " + r.InheritedPermissions)

			if r.Dir {
				children, err := fs.ReadDir(r)
				if err != nil {
					logrus.Fatal(err)
				}
				logrus.Info()
				logrus.Info("Children:")
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
					logrus.Info(formatResourceSummary(c))
				}
			} else {
				logrus.Info(fmt.Sprintf("         Size: %d", r.ContentSize))
				logrus.Info(" Content Type: " + r.ContentType)
				logrus.Info("   SHA256 Sum: " + r.ContentSHA256)
			}
		},
	}
	return &cmd
}
