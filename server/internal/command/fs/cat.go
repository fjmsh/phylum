package fs

import (
	"fmt"
	"io"
	"os"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

func setupCatCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "cat <path>",
		Short: "Output resource Contents",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			path := args[0]
			r, err := f.ResourceByPathWithRoot(path)
			if err != nil {
				fmt.Println("cannot locate '" + path + "': " + err.Error())
				os.Exit(1)
			}

			if r.Dir() {
				fmt.Println("cannot read '" + path + "': is a directory")
				os.Exit(1)
			}

			v, err := f.FindVersion(r, uuid.Nil)
			if err != nil {
				fmt.Println("cannot find latest version of '" + path + "': " + err.Error())
				os.Exit(1)
			}

			in, err := v.OpenRead(0, -1)
			if err != nil {
				fmt.Println("cannot read'" + path + "': " + err.Error())
				os.Exit(1)
			}
			if _, err := io.Copy(os.Stdout, in); err != nil {
				fmt.Println("cannot output'" + path + "': " + err.Error())
				os.Exit(1)
			}
		},
	}

	return &cmd
}
