package fs

import (
	"github.com/shroff/phylum/server/internal/command/fs/publink"
	"github.com/shroff/phylum/server/internal/command/fs/trash"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "fs",
		Short: "Filesystem",
	}
	cmd.PersistentFlags().StringP("user", "u", "", "User")

	cmd.AddCommand(
		setupCatCommand(),
		setupSetfaclCommand(),
		setupCpCommand(),
		setupImportCommand(),
		setupLsCommand(),
		setupMkdirCommand(),
		setupMvCommand(),
		setupRmCommand(),
		setupSearchCommand(),
		publink.SetupCommand(),
		trash.SetupCommand(),
	)

	return cmd
}
