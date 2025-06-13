package jobs

import (
	"context"

	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/riverqueue/river"
)

type DeleteContentsArgs struct {
	Name    string `json:"name"`
	Storage string `json:"storage"`
}

func (DeleteContentsArgs) Kind() string { return "delete_contents" }

type DeleteContentsWorker struct {
	river.WorkerDefaults[DeleteContentsArgs]
}

func (w *DeleteContentsWorker) Work(ctx context.Context, job *river.Job[DeleteContentsArgs]) error {
	if b, err := storage.GetBackend(job.Args.Storage); err != nil {
		return err
	} else {
		return b.Delete(job.Args.Name)
	}
}

func DeleteContents(args []DeleteContentsArgs) error {
	if len(args) == 0 {
		return nil
	}
	params := make([]river.InsertManyParams, len(args))
	for i, a := range args {
		params[i] = river.InsertManyParams{
			Args: a,
		}
	}
	_, err := client.InsertMany(context.Background(), params)
	return err
}
