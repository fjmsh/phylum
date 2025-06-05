package fs

import (
	"fmt"
	"os"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/spf13/cobra"
)

func setupMkdirCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "mkdir <path>",
		Short: "Create Directory",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			path := args[0]
			var recursive bool
			var conflict core.ResourceBindConflictResolution = core.ResourceBindConflictResolutionError
			if b, err := cmd.Flags().GetBool("parents"); err != nil {
				fmt.Println("could not read flag 'parents': " + err.Error())
				os.Exit(1)
			} else {
				recursive = b
				if recursive {
					conflict = core.ResourceBindConflictResolutionEnsure
				}
			}
			if _, err := f.CreateResourceByPath(path, uuid.Nil, true, recursive, conflict); err != nil {
				fmt.Println("could not create directory: " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("parents", "p", false, "Make intermediate parents as needed")
	return &cmd
}
