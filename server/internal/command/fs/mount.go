package fs

import (
	"context"
	"fmt"
	"os"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/spf13/cobra"
)

func setupMountCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "mount name path",
		Short: "Mout storage backend",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			name := args[0]
			path := args[1]

			backend, err := storage.GetBackend(name)
			if err != nil {
				fmt.Printf("failed to find storage backend: %s\n", err.Error())
				os.Exit(1)
			}

			if err := core.OpenOmniscient(db.Get(context.Background())).CreateMount(path, backend); err != nil {
				fmt.Printf("failed to mount storage backend: %s\n", err.Error())
				os.Exit(1)
			}
		},
	}
}
