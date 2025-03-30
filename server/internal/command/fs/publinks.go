package fs

import (
	"fmt"
	"os"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupPublinksCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "publinks {path | uuid}",
		Short: "List Publinks",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			pathOrUUID := args[0]
			r, err := f.ResourceByPathOrUUID(pathOrUUID)
			if err != nil {
				fmt.Println("cannot list publinks for '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}
			links, err := r.ListPublinks()
			if err != nil {
				fmt.Println("cannot list publinks for '" + pathOrUUID + "': " + err.Error())
				os.Exit(1)
			}
			for _, l := range links {
				fmt.Print(l.Name)
				if l.Deleted.Valid {
					fmt.Print(" (deleted)")
				}
				fmt.Printf(": accessed %d", l.Accessed)
				if l.MaxAccesses > 0 {
					fmt.Printf("/%d", l.MaxAccesses)
				}
				fmt.Print(" times")
				if l.PasswordHash != "" {
					fmt.Print(", password protected")
				}
				if l.Expires.Valid {
					fmt.Printf(", expires " + l.Expires.Time.String())
				}
				fmt.Println()
			}
		},
	}
	cmd.Flags().BoolP("parents", "p", false, "Make intermediate parents as needed")
	return &cmd
}
