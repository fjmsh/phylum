package fs

import (
	"errors"
	"fmt"
	iofs "io/fs"
	"os"
	"path"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

func setupImportCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "import <fs-path> <target> [name]",
		Short: "Import from filesystem",
		Args:  cobra.RangeArgs(2, 3),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			importPath := args[0]

			stat, err := os.Stat(importPath)
			if err != nil {
				fmt.Println("unable to stat '" + importPath + "': " + err.Error())
				os.Exit(1)
			}

			destName := stat.Name()
			if len(args) > 2 {
				destName = args[2]
			}

			if stat.IsDir() {
				if recursive, _ := cmd.Flags().GetBool("recursive"); !recursive {
					fmt.Println("could not import '" + importPath + "': is a directory. use -r to import")
					os.Exit(1)
				}
			}

			rootPath := args[1] + "/" + destName
			rootID, _ := uuid.NewV7()
			var conflictResolution core.ResourceBindConflictResolution = core.ResourceBindConflictResolutionError
			force, _ := cmd.Flags().GetBool("force")
			if force {
				conflictResolution = core.ResourceBindConflictResolutionDelete
			}

			if !stat.IsDir() {
				in, err := os.Open(importPath)
				if err == nil {
					versionID, _ := uuid.NewV7()
					_, err = f.CreateFileByPath(rootPath, rootID, versionID, in, conflictResolution)
					in.Close()
				}
			} else {
				var rootPrefix string
				if root, err := f.Mkdir(rootPath, rootID, false, conflictResolution); err != nil {
					if err == core.ErrResourceNameConflict {
						err = errors.New("resource with name '" + destName + "' already exist. use -f to overwrite")
					}
					fmt.Println("failed to create root resource: " + err.Error())
					os.Exit(1)
				} else {
					rootPrefix = ":" + root.ID().String() + "/"
				}
				dirFS := os.DirFS(importPath)

				err = iofs.WalkDir(dirFS, ".", func(p string, d iofs.DirEntry, err error) error {
					if p != "." && err == nil {
						resourceID, _ := uuid.NewV7()
						if d.IsDir() {
							_, err := f.Mkdir(rootPrefix+p, resourceID, false, core.ResourceBindConflictResolutionError)
							if err != nil {
								return err
							}
						} else {
							in, err := os.Open(path.Join(importPath, p))
							if err == nil {
								versionID, _ := uuid.NewV7()
								_, err = f.CreateFileByPath(rootPrefix+p, resourceID, versionID, in, core.ResourceBindConflictResolutionError)
								in.Close()
							}
						}
					}
					return err
				})
				//TODO #jobs. We don't need to run or wait for all jobs
				fmt.Println("Waiting for jobs to finish")
			}

			if err != nil {
				fmt.Println("could not import '" + importPath + "': " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().BoolP("force", "f", false, "Overwrite destination if it exists")
	cmd.Flags().BoolP("recursive", "r", false, "Recursive import")
	return &cmd
}
