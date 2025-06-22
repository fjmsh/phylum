package jobs

import (
	"context"
	"fmt"
	"os"
	"strconv"
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
		setupInfoCommand(),
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
			printJobInfo(j)
		}
	}
	cmd.Flags().StringSlice("status-only", []string{}, "Show only jobs matching the given status(es)")
	cmd.Flags().StringSlice("status-exclude", []string{}, "Exclude jobs matching the given status(es)")
	return cmd
}

func printJobInfo(info steve.JobInfo) {
	fmt.Printf("%4d %5s %s %s\n", info.ID, info.Status.String(), info.Kind, info.EncodedArgs)
}

func setupInfoCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "info <id>",
		Short: "Job Info",
		Args:  cobra.ExactArgs(1),
	}
	cmd.Run = func(cmd *cobra.Command, args []string) {
		client := steve.Get()

		id, err := strconv.ParseInt(args[0], 10, 32)
		if err != nil {
			fmt.Printf("failed to parse job id %q: %s", args[1], err.Error())
			os.Exit(1)
		}

		if _, err := client.Triage(); err != nil {
			fmt.Println("failed to triage jobs: " + err.Error())
			os.Exit(1)
		}

		job, err := steve.GetJobDetails(db.Get(context.Background()), int(id))
		if err != nil {
			fmt.Println("failed to get job details: " + err.Error())
			os.Exit(1)
		}
		fmt.Println("       ID: " + strconv.Itoa(int(job.ID)))
		fmt.Println("     Kind: " + job.Kind)
		fmt.Println("     Args: " + string(job.EncodedArgs))
		fmt.Println("  Created: " + job.CreatedAt.Format(time.RFC1123))
		fmt.Println("   Status: " + job.Status.String())
		if job.ScheduledAt.Valid {
			fmt.Println("Scheduled: " + job.ScheduledAt.Time.Format(time.RFC1123))
		}
		if len(job.Dependencies) != 0 {
			fmt.Println()
			fmt.Println("Blocked By:")
			for _, d := range job.Dependencies {
				printJobInfo(d)
			}
		}

		if len(job.Errors) != 0 {
			fmt.Println()
			fmt.Println("Errors:")
			for _, err := range job.Errors {
				fmt.Printf("%s: %s\n", err.At.Format(time.DateTime), err.Error)
			}
		}

		if len(job.Dependents) != 0 {
			fmt.Println()
			fmt.Println("Blocking:")
			for _, d := range job.Dependents {
				printJobInfo(d)
			}
		}
	}
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
