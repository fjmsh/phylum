package jobs

import (
	"context"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/img"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
)

type DeleteContentsArgs struct {
	Name    string  `json:"name"`
	Storage string  `json:"storage"`
	ImgRes  img.Res `json:"imgres"`
}

func (a DeleteContentsArgs) Kind() string        { return "delete_contents" }
func (a DeleteContentsArgs) Sequences() []string { return []string{a.Name} }
func (a DeleteContentsArgs) Blocking() bool      { return true }
func (a DeleteContentsArgs) MaxAttempts() int    { return 0 }

type DeleteContentsWorker struct {
	steve.WorkerDefaults[DeleteContentsArgs]
}

func (w *DeleteContentsWorker) Work(ctx context.Context, job *steve.Job[DeleteContentsArgs]) error {
	if b, err := storage.GetBackend(job.Args.Storage); err != nil {
		return err
	} else if err := b.Delete(job.Args.Name); err != nil {
		return err
	}
	return img.Delete(job.Args.Name, job.Args.ImgRes)
}

func DeleteContents(db db.Handler, args []DeleteContentsArgs) error {
	params := make([]steve.JobArgs, len(args))
	for i, a := range args {
		params[i] = a
	}
	return steve.Get().InsertJobs(db, params)
}
