package fs

import (
	"errors"
	"fmt"
	"io"
	"os"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func setupImportCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "import (<path> | <uuid>) <fs-path> [<name>]",
		Short: "Import from filesystem",
		Args:  cobra.RangeArgs(2, 3),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			target, err := f.ResourceByPathOrUUID(args[0])
			if err != nil {
				fmt.Println("could not import '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}

			stat, err := os.Stat(args[1])
			if err != nil {
				fmt.Println("could not import '" + args[1] + "': " + err.Error())
				os.Exit(1)
			}
			name := stat.Name()
			if len(args) > 2 {
				name = args[2]
			}

			force, _ := cmd.Flags().GetBool("force")
			if force {
				f.DeleteChildRecursive(target, name, true)
			} else {
				_, err := f.WithRoot(target.ID).ResourceByPath(name)
				if err == nil {
					fmt.Println("could not import '" + args[1] + "': resource with name '" + name + "' already exist. use -f to overwrite")
					os.Exit(1)
				} else if !errors.Is(err, fs.ErrResourceNotFound) {
					fmt.Println("could not import '" + args[1] + "': " + err.Error())
					os.Exit(1)
				}
			}
			if stat.IsDir() {

			} else {
				in, err := os.Open(args[1])
				if err != nil {
					fmt.Println("could not import '" + args[1] + "': " + err.Error())
				}
				defer in.Close()
				id, _ := uuid.NewUUID()
				if r, err := f.CreateMemberResource(target, id, name, false); err != nil {
					fmt.Println("could not import '" + args[1] + "': " + err.Error())
				} else {
					out, err := f.OpenWrite(r)
					if err != nil {
						fmt.Println("could not import '" + args[1] + "': " + err.Error())
					}
					defer out.Close()
					_, err = io.Copy(out, in)
					if err != nil {
						fmt.Println("could not import '" + args[1] + "': " + err.Error())
					}
				}
			}
		},
	}
	cmd.Flags().BoolP("force", "f", false, "Overwrite destination if it exists")
	return &cmd
}
