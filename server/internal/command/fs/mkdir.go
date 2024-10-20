package fs

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
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
			if _, err := f.CreateResourceByPath(path, true); err != nil {
				fmt.Println("could not create directory: " + err.Error())
				os.Exit(1)
			}
		},
	}
	return &cmd
}
