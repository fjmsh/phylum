package jobs

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

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
		setupExecuteCommand(),
	}...)

	return cmd
}

func setupListCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "list",
		Short: "List Jobs",
	}
	cmd.Run = func(cmd *cobra.Command, args []string) {
		onlyStr, _ := cmd.Flags().GetStringSlice("status-only")
		excludeStr, _ := cmd.Flags().GetStringSlice("status-exclude")
		var only, exclude []steve.JobStatus

		for _, s := range onlyStr {
			if st, err := strToStatus(s); err != nil {
				fmt.Println("failed to list jobs: " + err.Error())
			} else {
				only = append(only, st)
			}
		}
		for _, s := range excludeStr {
			if st, err := strToStatus(s); err != nil {
				fmt.Println("failed to list jobs: " + err.Error())
			} else {
				exclude = append(exclude, st)
			}
		}
		jobs, err := steve.Get().ListJobs(only, exclude)
		if err != nil {
			fmt.Println("failed to list jobs: " + err.Error())
			os.Exit(1)
		}
		for _, j := range jobs {
			printJobInfo(j)
		}
	}
	cmd.Flags().StringSliceP("status-only", "o", []string{}, "Show only jobs matching the given status(es)")
	cmd.Flags().StringSliceP("status-exclude", "x", []string{}, "Exclude jobs matching the given status(es)")
	return cmd
}
func strToStatus(s string) (steve.JobStatus, error) {
	switch strings.TrimSpace(strings.ToLower(s)) {
	case "queue":
		return steve.JobStatusQueued, nil
	case "block":
		return steve.JobStatusBlocked, nil
	case "ready":
		return steve.JobStatusReady, nil
	case "run":
		return steve.JobStatusRunning, nil
	case "done":
		return steve.JobStatusCompleted, nil
	case "error":
		return steve.JobStatusErrorRetry, nil
	case "fail":
		return steve.JobStatusFailed, nil
	}
	return steve.JobStatus(0), fmt.Errorf("failed to parse job status %q", s)
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

		job, err := steve.Get().GetJobDetails(int32(id))
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

func setupExecuteCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "execute <id>",
		Short: "Execute Job",
		Args:  cobra.ExactArgs(1),
	}
	cmd.Run = func(cmd *cobra.Command, args []string) {
		client := steve.Get()

		id, err := strconv.ParseInt(args[0], 10, 32)
		if err != nil {
			fmt.Printf("failed to parse job id %q: %s", args[1], err.Error())
			os.Exit(1)
		}

		if err := client.RunJob(context.Background(), int32(id)); err != nil {
			fmt.Println("failed to execute jobs: " + err.Error())
			os.Exit(1)
		}
	}
	return cmd
}
