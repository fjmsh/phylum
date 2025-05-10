package fs

import (
	"fmt"
	"os"
	"time"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupPublinksCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "publinks <path>",
		Short: "List Publinks",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			pathOrUUID := args[0]
			r, err := f.ResourceByRootedPath(pathOrUUID)
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
				fmt.Print(l.ID)
				fmt.Printf(": accessed %d", l.Accessed)
				if l.AccessLimit > 0 {
					fmt.Printf("/%d", l.AccessLimit)
				}
				fmt.Print(" times")
				if l.PasswordHash != "" {
					fmt.Print(", password protected")
				}
				if l.Expires != 0 {
					expires := time.UnixMilli(l.Expires)
					if expires.Before(time.Now()) {
						fmt.Print(", EXPIRED ")
					} else {
						fmt.Print(", expires")
					}
					fmt.Print(expires.Format(time.RFC1123))
				}
				fmt.Println()
			}
		},
	}
	cmd.Flags().BoolP("parents", "p", false, "Make intermediate parents as needed")
	return &cmd
}
