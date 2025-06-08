package fs

import (
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

func setupCopyCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:     "copy <src> <dest>",
		Aliases: []string{"cp"},
		Short:   "Copy Resource",
		Args:    cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			srcPath := args[0]
			src, err := f.ResourceByPathWithRoot(srcPath)
			if err != nil {
				fmt.Println("cannot copy'" + srcPath + "': " + err.Error())
				os.Exit(1)
			}

			force, _ := cmd.Flags().GetBool("force")
			if src.Dir() {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					fmt.Println("cannot copy'" + srcPath + "' to '" + args[1] + "': must use -r to copy directories")
					os.Exit(1)
				}
			}

			id, _ := uuid.NewV7()
			var conflictResolution core.ResourceBindConflictResolution = core.ResourceBindConflictResolutionError
			if force {
				conflictResolution = core.ResourceBindConflictResolutionOverwrite
			}
			if _, _, err := f.Copy(src, args[1], id, true, conflictResolution); err != nil {
				fmt.Println("cannot copy'" + srcPath + "' to '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}
