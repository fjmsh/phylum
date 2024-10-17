package fs

import (
	"errors"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupRmCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "rm path",
		Short: "Delete Resource",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			r, err := fs.ResourceByPath(path)
			if err != nil {
				if errors.Is(err, core.ErrResourceNotFound) {
					logrus.Fatal("Resource not found: " + path)
				} else {
					logrus.Fatal(err.Error())
				}
			}

			if r.Dir {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					logrus.Fatal("Must use -r to delete directories")
				}
			}

			fs.DeleteRecursive(r, true)
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")

	return &cmd
}
