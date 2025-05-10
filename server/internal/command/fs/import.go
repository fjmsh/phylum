package fs

import (
	"errors"
	"fmt"
	"io"
	iofs "io/fs"
	"os"
	"path"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
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
				if fs.CheckNameInvalid(destName) {
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

			var size int = 0
			create := make([]fs.CreateResourcesParams, 0)
			copy := make(map[string]uuid.UUID)
			ids := make(map[string]uuid.UUID)
			targetRootID, _ := uuid.NewV7()
			ids["."] = targetRootID

			if stat.IsDir() {
				dirFS := os.DirFS(importPath)

				err := iofs.WalkDir(dirFS, ".", func(p string, d iofs.DirEntry, err error) error {
					if p != "." && err == nil {
						info, err := d.Info()
						if err != nil {
							return err
						}
						len := int(info.Size())
						if d.IsDir() {
							len = 0
						}
						size += len
						if fs.CheckNameInvalid(d.Name()) {
							return fs.ErrResourceNameInvalid
						}
						ids[p], _ = uuid.NewV7()
						parent := ids[path.Dir(p)]
						create = append(create, fs.CreateResourcesParams{
							Parent:        parent,
							ID:            ids[p],
							Name:          d.Name(),
							Dir:           d.IsDir(),
							ContentLength: len,
							ContentType:   "",
							ContentSha256: "",
						})
						if !d.IsDir() {
							copy[p] = ids[p]
						}

					}
					return err
				})
				if err != nil {
					fmt.Println("could not import '" + importPath + "': " + err.Error())
					os.Exit(1)
				}
			}
			fmt.Printf("Importing %d files (%d bytes) across %d dirs\n", len(copy), size, 1+len(create)-len(copy))

			var conflictResolution fs.ResourceBindConflictResolution = fs.ResourceBindConflictResolutionError
			if force {
				conflictResolution = fs.ResourceBindConflictResolutionDelete
			}
			err = f.RunInTx(func(f fs.FileSystem) error {
				if _, err = f.CreateResourceByPath(args[1]+"/"+destName, targetRootID, stat.IsDir(), false, conflictResolution); err != nil {
					if err == fs.ErrResourceNameConflict {
						err = errors.New("resource with name '" + destName + "' already exist. use -f to overwrite")
					}
					return err
				}
				_, err = f.CreateResources(create)
				return err
			})

			if err == nil {
				err = func() error {
					for k, v := range copy {
						if err := copyContents(f, path.Join(importPath, k), v); err != nil {
							return errors.New("unable to copy " + k + " to " + v.String() + ": " + err.Error())
						}
					}
					return nil
				}()
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

func copyContents(f fs.FileSystem, src string, id uuid.UUID) error {
	fmt.Println("importing " + src + " to " + id.String())
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	if r, err := f.ResourceByID(id); err != nil {
		return err
	} else {
		out, err := r.OpenWrite()
		if err != nil {
			return err
		}
		defer out.Close()
		_, err = io.Copy(out, in)
		if err != nil {
			return err
		}
	}

	return nil
}
