package fs

import (
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/spf13/cobra"
)

func setupMoveCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:     "move <src> <dest>",
		Aliases: []string{"mv", "rename"},
		Short:   "Move Resource",
		Args:    cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			srcPath := args[0]
			src, err := f.ResourceByPath(srcPath)
			if err != nil {
				fmt.Println("cannot move'" + srcPath + "': " + err.Error())
				os.Exit(1)
			}

			force, _ := cmd.Flags().GetBool("force")

			var conflictResolution core.ResourceBindConflictResolution = core.ResourceBindConflictResolutionError
			if force {
				conflictResolution = core.ResourceBindConflictResolutionDelete
			}
			if _, _, err := f.Move(src, args[1], conflictResolution); err != nil {
				fmt.Println("cannot move'" + srcPath + "' to '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}
