package fs

import (
	"strings"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func setupMkdirCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "mkdir <path>",
		Short: "Create Directory",
		Args:  cobra.ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			path := args[0]
			if _, err := f.ResourceByPath(path); err == nil {
				logrus.Fatal("Resource already exists: " + path)
			}
			// TODO: Streamline with WebDAV mkcol request handling
			path = strings.TrimRight(path, "/")
			index := strings.LastIndex(path, "/")
			parentPath := path[0:index]
			parent, err := f.ResourceByPath(parentPath)

			if err != nil {
				logrus.Fatal("Parent resource does not exist: " + parentPath)
			}

			id := uuid.New()
			name := path[index+1:]
			if _, err = f.CreateMemberResource(parent, id, name, true); err != nil {
				logrus.Fatal(err)
			} else {
				logrus.Info("Created directory " + path + " (" + id.String() + ")")
			}
		},
	}
	return &cmd
}
