package trash

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/shroff/phylum/server/internal/command/common"
	"github.com/spf13/cobra"
)

func setupEmptyCommand() *cobra.Command {
	cmd := cobra.Command{
		Use:   "empty",
		Short: "Empty Trash",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			f := common.UserFileSystem(cmd)
			printTrashSummary(f)
			if noConfirm, err := cmd.Flags().GetBool("no-confirm"); err != nil {
				fmt.Println("cannot read flag: " + err.Error())
				os.Exit(1)
			} else if !noConfirm {
				reader := bufio.NewReader(os.Stdin)
				fmt.Print("Are you sure you want to continue (y/N)?: ")
				text, _ := reader.ReadString('\n')
				text = strings.TrimLeft(text, "\r\n\t ")
				text = strings.TrimRight(text, "\r\n\t ")
				if text != "Y" && text != "y" {
					fmt.Println("Aborting")
					os.Exit(0)
				}
			}
			fmt.Println("Deleting")
			f.TrashEmpty()
		},
	}
	cmd.Flags().BoolP("no-confirm", "y", false, "Do not ask for confirmation")
	return &cmd
}
