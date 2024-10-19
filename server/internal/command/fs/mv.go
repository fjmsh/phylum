package fs

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

func setupMvCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "mv [<src-path> | <src-uuid>] [<dest-path> | <dest-name> | <dest-uuid>/<dest-name>]",
		Short: "Move Resource",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			srcPathOrUuid := args[0]
			src, err := f.ResourceByPathOrUuid(srcPathOrUuid)
			if err != nil {
				fmt.Println("cannot move'" + srcPathOrUuid + "': " + err.Error())
				os.Exit(1)
			}

			force, _ := cmd.Flags().GetBool("force")

			if _, err := f.Move(src, args[1], force); err != nil {
				fmt.Println("cannot move'" + srcPathOrUuid + "' to '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("force", "f", false, "Overwrite without prompting")

	return &cmd
}
