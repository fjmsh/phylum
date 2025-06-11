package jobs

import (
	"context"

	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/riverqueue/river"
)

type CopyContentsArgs struct {
	Name    string `json:"name"`
	Storage string `json:"storage"`
}

func (CopyContentsArgs) Kind() string { return "copy_contents" }

type CopyContentsWorker struct {
	river.WorkerDefaults[CopyContentsArgs]
}

func (w *CopyContentsWorker) Work(ctx context.Context, job *river.Job[CopyContentsArgs]) error {
	if b, err := storage.GetBackend(job.Args.Storage); err != nil {
		return err
	} else {
		return b.Delete(job.Args.Name)
	}
}
