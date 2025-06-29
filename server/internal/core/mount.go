package core

import (
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/storage"
)

func (f FileSystem) CreateMount(path string, backend storage.Backend) error {
	r, err := f.ResourceByPathWithRoot(path)
	if err != nil {
		fmt.Println("failed to locate resource: " + err.Error())
		os.Exit(1)
	}

	const q = `INSERT INTO storage_mounts(id, storage) VALUES ($1, $2) ON CONFLICT(id) DO UPDATE SET storage = $2`
	_, err = f.db.Exec(q, r.id, backend.Name())
	return err
}
