package jobs

import (
	"context"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/img"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"github.com/google/uuid"
)

type CopyImgsArgs struct {
	Src    uuid.UUID `json:"src"`
	Dest   uuid.UUID `json:"dest"`
	ImgRes uint8     `json:"imgres"`
}

func (a CopyImgsArgs) Kind() string        { return "copy_imgs" }
func (a CopyImgsArgs) Sequences() []string { return []string{a.Src.String(), a.Dest.String()} }
func (a CopyImgsArgs) Blocking() bool      { return false }
func (a CopyImgsArgs) MaxAttempts() int    { return 3 }

type CopyImgsWorker struct {
	steve.WorkerDefaults[CopyImgsArgs]
}

func (w *CopyImgsWorker) Work(ctx context.Context, job *steve.Job[CopyImgsArgs]) error {
	return img.Copy(job.Args.Src.String(), job.Args.Dest.String(), job.Args.ImgRes)
}

func CopyImgsMany(db db.Handler, args []CopyImgsArgs) error {
	params := make([]steve.JobArgs, len(args))
	for i, a := range args {
		params[i] = a
	}
	return steve.Get().InsertJobs(db, params)
}
