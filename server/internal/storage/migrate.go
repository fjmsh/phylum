package storage

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

func Migrate(name string, dryRun bool) error {
	var src localStorage
	if b, err := GetBackendByName(name); err != nil {
		return err
	} else if local, ok := b.(localStorage); !ok {
		return errors.New("Storage backend is not local: " + name)
	} else {
		src = local
	}
	fmt.Printf("Migrating files for storage backend `%s` located at %s\n", src.name, src.root)

	files, err := os.ReadDir(src.root)
	if err != nil {
		return err
	}
	for _, f := range files {
		if f.IsDir() {
			continue
		}
		in := filepath.Join(src.root, f.Name())
		if dryRun {
			fmt.Printf("Moving %s to %s\n", in, src.Path(f.Name()))
		} else if err := src.mkdirs(f.Name()); err != nil {
			return err
		} else if err := os.Rename(in, src.Path(f.Name())); err != nil {
			return err
		}
	}
	return nil
}
