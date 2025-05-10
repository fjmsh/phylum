package fs

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func setupMvCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "mv <src> <dest>",
		Short: "Move Resource",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			srcPath := args[0]
			src, err := f.ResourceByPathWithRoot(srcPath)
			if err != nil {
				fmt.Println("cannot move'" + srcPath + "': " + err.Error())
				os.Exit(1)
			}

			force, _ := cmd.Flags().GetBool("force")

			var conflictResolution fs.ResourceBindConflictResolution = fs.ResourceBindConflictResolutionError
			if force {
				conflictResolution = fs.ResourceBindConflictResolutionDelete
			}
			if _, _, err := src.Move(args[1], conflictResolution); err != nil {
				fmt.Println("cannot move'" + srcPath + "' to '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}
