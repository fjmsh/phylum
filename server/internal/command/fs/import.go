package fs

import (
	"context"
	"errors"
	"fmt"
	"io"
	iofs "io/fs"
	"os"
	"path/filepath"

	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
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
				if core.CheckResourceNameInvalid(destName) {
					fmt.Println("invalid name: '" + destName + "'")
				}
			}

			if stat.IsDir() {
				if recursive, _ := cmd.Flags().GetBool("recursive"); !recursive {
					fmt.Println("could not import '" + importPath + "': is a directory. use -r to import")
					os.Exit(1)
				}
			}

			force, _ := cmd.Flags().GetBool("force")
			targetRootID, _ := uuid.NewV7()
			var conflictResolution core.ResourceBindConflictResolution = core.ResourceBindConflictResolutionError
			if force {
				conflictResolution = core.ResourceBindConflictResolutionDelete
			}
			var res core.Resource
			if res, err = f.CreateResourceByPath(args[1]+"/"+destName, targetRootID, stat.IsDir(), false, conflictResolution); err != nil {
				if err == core.ErrResourceNameConflict {
					err = errors.New("resource with name '" + destName + "' already exist. use -f to overwrite")
				}
				fmt.Println("failed to create root resource: " + err.Error())
				os.Exit(1)
			}

			if stat.IsDir() {
				jobs.Initialize(context.Background(), db.Pool())
				dirFS := os.DirFS(importPath)

				err = iofs.WalkDir(dirFS, ".", func(p string, d iofs.DirEntry, err error) error {
					if p != "." && err == nil {
						if core.CheckResourceNameInvalid(d.Name()) {
							return core.ErrResourceNameInvalid
						}
						id, _ := uuid.NewV7()
						res, err := f.CreateResourceByPath(targetRootID.String()+":"+p, id, d.IsDir(), false, core.ResourceBindConflictResolutionError)
						if err != nil {
							return err
						}

						if !d.IsDir() {
							path := filepath.Join(importPath, p)
							return copyContents(f, path, res)
						}
					}
					return err
				})
				//TODO #jobs. We don't need to run or wait for all jobs
				fmt.Println("Waiting for jobs to finish")
				jobs.Shutdown(context.Background())
			} else {
				err = copyContents(f, importPath, res)
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

func copyContents(f core.FileSystem, path string, res core.Resource) error {
	in, err := os.Open(path)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := f.CreateFileVersion(res, uuid.Nil)
	if err != nil {
		return err
	}

	_, copyErr := io.Copy(out, in)
	closeErr := out.Close()
	if copyErr != nil {
		return copyErr
	}
	return closeErr
}
