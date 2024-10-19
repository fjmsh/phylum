package util

import (
	"context"
	"errors"

	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func OpenFileSystemFromFlags(cmd *cobra.Command) (fs.FileSystem, error) {
	if value, err := cmd.Flags().GetString("user"); err != nil {
		return nil, errors.New("could not read user: " + err.Error())
	} else {
		if user, err := app.Default.UserByEmail(context.Background(), value); err != nil {
			return nil, errors.New("could not find user '" + value + "': " + err.Error())
		} else {
			return app.Default.OpenFileSystem(context.Background(), user), nil
		}
	}
}
