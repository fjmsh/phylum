package migrate

import (
	"fmt"

	"codeberg.org/shroff/phylum/server/internal/img"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "migrate",
		Short: "Breaking Migrations",
	}
	cmd.AddCommand([]*cobra.Command{
		setupImgCommand(),
		setupLocalstorageCommand(),
	}...)
	return cmd
}

func setupImgCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "img",
		Short: "Migrate Images",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			dryRun, _ := cmd.Flags().GetBool("dry-run")
			if err := img.Migrate(args[0], dryRun); err != nil {
				fmt.Printf("Error performing migration: %v\n", err)
			}
		},
	}
	cmd.Flags().BoolP("dry-run", "n", false, "Dry Run: Only list what is to be done")
	return cmd
}

func setupLocalstorageCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "localstorage",
		Short: "Migrate Local Storage Structure",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			dryRun, _ := cmd.Flags().GetBool("dry-run")
			name := storage.DefaultBackendName
			if len(args) > 0 {
				name = args[0]
			}
			if err := storage.Migrate(name, dryRun); err != nil {
				fmt.Printf("Error performing migration: %v\n", err)
			}
		},
	}
	cmd.Flags().BoolP("dry-run", "n", false, "Dry Run: Only list what is to be done")
	return cmd
}
