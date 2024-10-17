package fs

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var fs core.FileSystem

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

			if err := db.Default.CheckVersion(context.Background(), !viper.GetBool("no_auto_migrate")); err != nil {
				fmt.Println("could not migrate database schema: " + err.Error())
				os.Exit(1)
			}
			if err := storage.Create(context.Background(), db.Default, viper.GetString("default_storage_dir")); err != nil {
				fmt.Println("could not open storage: " + err.Error())
				os.Exit(1)
			}
			if err := core.Create(context.Background(), db.Default, storage.Default); err != nil {
				fmt.Println("could not initialized app: " + err.Error())
				os.Exit(1)
			}
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

func openFileSystemFromFlags(cmd *cobra.Command) {
	if value, err := cmd.Flags().GetString("user"); err != nil {
		fmt.Println("could not read user: " + err.Error())
		os.Exit(1)
	} else {
		if user, err := core.Default.UserByEmail(context.Background(), value); err != nil {
			fmt.Println("could not find user '" + value + "': " + err.Error())
			os.Exit(1)
		} else {
			fs = core.Default.OpenFileSystem(context.Background(), user)
		}
	}
}

func resourceByPathOrUuid(pathOrUuid string) (core.Resource, error) {
	if pathOrUuid[0] == '/' {
		return fs.ResourceByPath(pathOrUuid)
	}
	if id, err := uuid.Parse(pathOrUuid); err != nil {
		return core.Resource{}, err
	} else {
		return fs.ResourceByID(id)
	}
}

func targetResourceByPathOrUuid(pathOrUuid string) (core.Resource, string, error) {
	if pathOrUuid[0] == '/' {
		path := strings.TrimRight(pathOrUuid, "/")
		if dest, err := fs.ResourceByPath(path); err == nil {
			return dest, "", nil
		} else {
			index := strings.LastIndex(path, "/")
			name := path[index+1:]
			path = path[0:index]
			if parent, err := fs.ResourceByPath(path); err != nil {
				return core.Resource{}, "", err
			} else {
				return parent, name, nil
			}
		}
	}
	index := strings.Index(pathOrUuid, "/")
	if id, err := uuid.Parse(pathOrUuid[0:index]); err != nil {
		return core.Resource{}, "", err
	} else if parent, err := fs.ResourceByID(id); err != nil {
		return core.Resource{}, "", err
	} else {
		return parent, pathOrUuid[:index+1], nil
	}
}
