package publink

import (
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/shroff/phylum/server/internal/core/fs"
	"github.com/spf13/cobra"
)

func setupCreateCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "create <name> (<path> | <uuid>)",
		Short: "Create Publink",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			password, _ := cmd.Flags().GetString("password")
			duration, _ := cmd.Flags().GetString("duration")
			accesses, _ := cmd.Flags().GetInt("accesses")
			if err := createPublink(common.UserFileSystem(cmd), args[0], args[1], password, duration, accesses); err != nil {
				fmt.Println("could not create publink '" + args[0] + "': " + err.Error())
			}
		},
	}

	cmd.Flags().StringP("password", "p", "", "Password")
	cmd.Flags().StringP("duration", "d", "", "Duration")
	cmd.Flags().IntP("accesses", "a", 0, "Accesses")
	return &cmd
}

func createPublink(f fs.FileSystem, name, path string, password string, durationStr string, accesses int) error {
	r, err := f.ResourceByRootedPath(path)
	if err != nil {
		return err
	}
	var expires pgtype.Timestamp
	if durationStr != "" {
		var err error
		duration, err := time.ParseDuration(durationStr)
		if err != nil {
			return err
		}
		if duration < 0 {
			return errors.New("duration cannot be negative: " + duration.String())
		}
		expires = pgtype.Timestamp{
			Time:  time.Now().Add(duration),
			Valid: true,
		}
	}

	return r.CreatePublink(name, password, expires, accesses)
}
