package fs

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupMvCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "mv [<src-path> | <src-uuid>] [<dest-path> | <dest-name> | <dest-uuid>/<dest-name>]",
		Short: "Move Resource",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			srcPathOrUUID := args[0]
			src, err := f.ResourceByPathOrUUID(srcPathOrUUID)
			if err != nil {
				fmt.Println("cannot move'" + srcPathOrUUID + "': " + err.Error())
				os.Exit(1)
			}

			force, _ := cmd.Flags().GetBool("force")

			if _, _, err := f.Move(src, args[1], force); err != nil {
				fmt.Println("cannot move'" + srcPathOrUUID + "' to '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}
