package fs

import (
	"context"
	"errors"
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/app"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var f fs.FileSystem

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "fs",
		Short: "Filesystem Access",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			// Run root command persistent pre-run
			c := cmd.Parent()
			for ; c.Parent() != nil; c = c.Parent() {
			}
			c.PersistentPreRun(cmd, args)

			if viper.GetBool("no_auto_migrate") {
				common.MustInitializeDB(false)
			}
			common.MustInitializeApp()
			mustOpenFileSystemFromFlags(cmd)
		},
	}
	flags := cmd.PersistentFlags()
	flags.Bool("no-auto-migrate", false, "Do not automatically migrate database schema")
	viper.BindPFlag("no_auto_migrate", flags.Lookup("no-auto-migrate"))

	flags.StringP("default-storage-dir", "S", "storage/default", "Default Storage Directory")
	viper.BindPFlag("default_storage_dir", flags.Lookup("default-storage-dir"))

	flags.StringP("user", "u", "phylum", "Specify user for resource operations")

	cmd.AddCommand(
		setupLsCommand(),
		setupMkdirCommand(),
		setupRmCommand(),
		setupCpCommand(),
		setupChpermCommand(),
	)

	return cmd
}

func mustOpenFileSystemFromFlags(cmd *cobra.Command) {
	var err error
	f, err = openFileSystemFromFlags(cmd)
	if err != nil {
		fmt.Println("could not open filesystem: " + err.Error())
		os.Exit(4)
	}
}

func openFileSystemFromFlags(cmd *cobra.Command) (fs.FileSystem, error) {
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
