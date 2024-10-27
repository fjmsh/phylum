package public

import (
	"fmt"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func setupCreateCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "create <name> (<path> | <uuid>)",
		Short: "Create Public Share",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			if err := createPublicShare(common.UserFileSystem(cmd), args[0], args[1]); err != nil {
				fmt.Println("could not create public share '" + args[0] + "': " + err.Error())
			}
		},
	}
	return &cmd
}

func createPublicShare(f fs.FileSystem, name, pathOrUUID string) error {
	r, err := f.ResourceByPathOrUUID(pathOrUUID)
	if err != nil {
		return err
	}
	return r.CreatePublicShare(name, nil, nil, nil)
}
