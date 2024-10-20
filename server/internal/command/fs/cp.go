package fs

import (
	"fmt"
	"os"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupCpCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "cp [<src-path> | <src-uuid>] [<dest-path> | <dest-uuid>/<dest-name>]",
		Short: "Copy Resource",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			srcPathOrUUID := args[0]
			src, err := f.ResourceByPathOrUUID(srcPathOrUUID)
			if err != nil {
				fmt.Println("cannot copy'" + srcPathOrUUID + "': " + err.Error())
				os.Exit(1)
			}

			force, _ := cmd.Flags().GetBool("force")
			if src.Dir {
				if recursive, err := cmd.Flags().GetBool("recursive"); err != nil || !recursive {
					fmt.Println("cannot copy'" + srcPathOrUUID + "' to '" + args[1] + "': must use -r to copy directories")
					os.Exit(1)
				}
			}

			if _, _, err := f.Copy(src, args[1], uuid.New(), true, force); err != nil {
				fmt.Println("cannot copy'" + srcPathOrUUID + "' to '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("recursive", "r", false, "Recursive (required for directories)")
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}
