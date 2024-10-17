package fs

import (
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupCpCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "cp <src-path> <dest-path>",
		Short: "Copy Resource",
		Args:  cobra.ExactArgs(2),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			srcPath := strings.TrimRight(args[0], "/")
			src, err := fs.ResourceByPath(srcPath)
			if err != nil {
				if errors.Is(err, core.ErrResourceNotFound) {
					logrus.Fatal("Resource not found: " + srcPath)
				}
				logrus.Fatal(err.Error())
			}
			var parentID uuid.UUID
			var name string
			parentPath := strings.TrimRight(args[1], "/")
			if dest, err := fs.ResourceByPath(parentPath); err == nil {
				if dest.Dir {
					parentID = dest.ID
					name = src.Name
				} else if src.Dir {
					logrus.Fatal(fmt.Sprintf("Cannot overwrite non-directory '%s' with directory '%s'", parentPath, srcPath))
				}
			} else {
				index := strings.LastIndex(parentPath, "/")
				name = parentPath[index+1:]
				parentPath = parentPath[0:index]
				if parent, err := fs.ResourceByPath(parentPath); err != nil {
					if errors.Is(err, core.ErrResourceNotFound) {
						logrus.Fatal("Directory does not exist: " + parentPath)
					}
					logrus.Fatal(err.Error())
				} else {
					parentID = parent.ID
				}
			}

			force, _ := cmd.Flags().GetBool("force")
			if src.Dir {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					logrus.Fatal("Must use -r to copy directories")
				}
			}

			if _, err := fs.Copy(src, uuid.New(), parentID, name, true, force); err != nil {
				logrus.Fatal(err.Error())
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}