package fs

import (
	"codeberg.org/shroff/phylum/server/internal/command/fs/publink"
	"codeberg.org/shroff/phylum/server/internal/command/fs/trash"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "fs",
		Short: "Filesystem",
	}
	cmd.PersistentFlags().StringP("user-email", "u", "", "User Email")

	cmd.AddCommand(
		setupCatCommand(),
		setupSetfaclCommand(),
		setupCopyCommand(),
		setupImportCommand(),
		setupInfoCommand(),
		setupMkdirCommand(),
		setupMoveCommand(),
		setupDeleteCommand(),
		setupSearchCommand(),
		publink.SetupCommand(),
		trash.SetupCommand(),
	)

	return cmd
}
