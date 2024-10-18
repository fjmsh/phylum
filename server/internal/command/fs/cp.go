package fs

import (
	"fmt"
	"os"

	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

func setupCpCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "cp [<src-path> | <src-uuid>] [<dest-path> | <dest-uuid>/<dest-name>]",
		Short: "Copy Resource",
		Args:  cobra.ExactArgs(2),
		PreRun: func(cmd *cobra.Command, args []string) {
			openFileSystemFromFlags(cmd)
		},
		Run: func(cmd *cobra.Command, args []string) {
			srcPathOrUuid := args[0]
			src, err := fs.ResourceByPathOrUuid(srcPathOrUuid)
			if err != nil {
				fmt.Println("cannot copy'" + srcPathOrUuid + "': " + err.Error())
				os.Exit(1)
			}

			force, _ := cmd.Flags().GetBool("force")
			if src.Dir {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					fmt.Println("cannot copy'" + srcPathOrUuid + "' to '" + args[1] + "': must use -r to copy directories")
					os.Exit(1)
				}
			}

			if _, err := fs.Copy(src, args[1], uuid.New(), true, force); err != nil {
				fmt.Println("cannot copy'" + srcPathOrUuid + "' to '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}
