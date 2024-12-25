package fs

import (
	"context"
	"errors"
	"fmt"
	"io"
	iofs "io/fs"
	"os"
	"path"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

const emptySHA = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

func setupImportCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "import (<path> | <uuid>) <fs-path> [<name>]",
		Short: "Import from filesystem",
		Args:  cobra.RangeArgs(2, 3),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			destParent, err := f.ResourceByPathOrUUID(args[0])
			importPath := args[1]
			if err != nil {
				fmt.Println("could not import '" + importPath + "': " + err.Error())
				os.Exit(1)
			}

			stat, err := os.Stat(importPath)
			if err != nil {
				fmt.Println("could not import '" + importPath + "': " + err.Error())
				os.Exit(1)
			}
			destName := stat.Name()
			if len(args) > 2 {
				destName = args[2]
				if destName == "" || fs.CheckNameInvalid(destName) {
					fmt.Println("could not import '" + importPath + "': name is invalid: '" + destName + "'")
				}
			}

			if stat.IsDir() {
				if recursive, _ := cmd.Flags().GetBool("recursive"); !recursive {
					fmt.Println("could not import '" + importPath + "': is a directory. use -r to import")
					os.Exit(1)
				}
			}

			force, _ := cmd.Flags().GetBool("force")

			var size int64 = 0
			create := make([]db.CreateResourcesParams, 0)
			copy := make(map[string]uuid.UUID)
			ids := make(map[string]uuid.UUID)
			ids["."], _ = uuid.NewV7()
			create = append(create, db.CreateResourcesParams{
				ID:     ids["."],
				Parent: destParent.ID(),
				Name:   destName,
				Dir:    stat.IsDir(),
			})

			if stat.IsDir() {
				dirFS := os.DirFS(importPath)

				err := iofs.WalkDir(dirFS, ".", func(p string, d iofs.DirEntry, err error) error {
					if p != "." && err == nil {
						info, err := d.Info()
						if err != nil {
							return err
						}
						sz := info.Size()
						if d.IsDir() {
							sz = 0
						}
						size += sz
						if d.Name() == "" || fs.CheckNameInvalid(d.Name()) {
							return fs.ErrResourceNameInvalid
						}
						ids[p], _ = uuid.NewV7()
						parent := ids[path.Dir(p)]
						create = append(create, db.CreateResourcesParams{
							Parent:        parent,
							ID:            ids[p],
							Name:          d.Name(),
							Dir:           d.IsDir(),
							ContentSize:   sz,
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
			fmt.Printf("Importing %d files (%d bytes) across %d dirs\n", len(copy), size, len(create)-len(copy))

			ctx := context.Background()
			err = db.Get().WithTx(ctx, func(dbh *db.DbHandler) error {
				f := f.WithDb(dbh)
				if force {
					if _, err := destParent.DeleteChildRecursive(destName, false); !errors.Is(err, fs.ErrResourceNotFound) {
						return err
					}
				} else {
					_, err := f.WithRoot(destParent.ID()).ResourceByPath(destName)
					if err == nil {
						return errors.New("resource with name '" + destName + "' already exist. use -f to overwrite")
					} else if !errors.Is(err, fs.ErrResourceNotFound) {
						return err
					}
				}
				if _, err := dbh.CreateResources(ctx, create); err != nil {
					if strings.Contains(err.Error(), "unique_member_resource_name") {
						return fs.ErrResourceNameConflict
					}
					return err
				}
				return dbh.UpdateResourceModified(ctx, destParent.ID())
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
