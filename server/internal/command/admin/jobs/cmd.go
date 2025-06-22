package jobs

import (
	"context"
	"fmt"
	"os"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "jobs",
		Short: "Job",
	}
	cmd.AddCommand([]*cobra.Command{
		setupListCommand(),
		setupTriageCommand(),
	}...)

	return cmd
}

func setupListCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "list",
		Short: "List Jobs",
	}
	cmd.Run = func(cmd *cobra.Command, args []string) {
		// only, _ := cmd.Flags().GetStringSlice("status-only")
		// exclude, _ := cmd.Flags().GetStringSlice("status-exclude")
		// for _, s := range only {
		// 	fmt.Println(s)
		// }
		// for _, s := range exclude {
		// 	fmt.Println(s)
		// }
		jobs, err := steve.ListJobs(db.Get(context.Background()), nil, nil)
		if err != nil {
			fmt.Println("failed to list jobs: " + err.Error())
			os.Exit(1)
		}
		for _, j := range jobs {
			fmt.Printf("%4d %s %5s %s %s\n", j.ID, j.CreatedAt.Format(time.DateTime), j.Status.String(), j.Kind, j.EncodedArgs)
		}
	}
	cmd.Flags().StringSlice("status-only", []string{}, "Show only jobs matching the given status(es)")
	cmd.Flags().StringSlice("status-exclude", []string{}, "Exclude jobs matching the given status(es)")
	return cmd
}

func setupTriageCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "triage",
		Short: "Triage Jobs",
		Run: func(cmd *cobra.Command, args []string) {
			if n, err := steve.Get().Triage(); err != nil {
				fmt.Println("failed to triage jobs: " + err.Error())
				os.Exit(1)
			} else {
				fmt.Printf("%d job statues updated\n", n)
			}
		},
	}
	return cmd
}
