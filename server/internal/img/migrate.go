package img

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/storage"
)

var suffixes = map[string]Res{
	"t": ResThumbnail,
	"l": ResLarge,
}

func Migrate(src string, dryRun bool) error {
	if !filepath.IsAbs(src) {
		src = filepath.Join(storage.Root, src)
	}
	fmt.Printf("Migrating files from %s to %s\n", src, dir)
	files, err := os.ReadDir(src)
	if err != nil {
		return err
	}
	for _, f := range files {
		if f.IsDir() {
			continue
		}
		if name, ok := strings.CutSuffix(f.Name(), ".webp"); ok {
			if res, ok := suffixes[name[len(name)-1:]]; ok {
				name = name[:len(name)-2]
				in := filepath.Join(src, f.Name())
				if dryRun {
					fmt.Printf("Moving %s to %s\n", in, path(name, res))
				} else if err := mkdirs(name, res); err != nil {
					return err
				} else if err := os.Rename(in, path(name, res)); err != nil {
					return err
				}
			}
		}
	}
	return nil
}
