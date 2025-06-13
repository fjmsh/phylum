package jobs

import (
	"context"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
	"github.com/riverqueue/river"
)

type CopyContentsArgs struct {
	Src  uuid.UUID `json:"src"`
	Dest uuid.UUID `json:"dest"`
}

func (CopyContentsArgs) Kind() string { return "copy_contents" }

type CopyContentsWorker struct {
	river.WorkerDefaults[CopyContentsArgs]
}

func (w *CopyContentsWorker) Work(ctx context.Context, job *river.Job[CopyContentsArgs]) error {
	return copyContents(ctx, job.Args.Src, job.Args.Dest)
}

func copyContents(ctx context.Context, src, dest uuid.UUID) error {
	db := db.Get(ctx)
	storage := storage.DefaultBackend()
	if current, err := getCurrentStorage(db, src); err != nil {
		return errors.New("failed to get src storage: " + err.Error())
	} else {
		return storage.Copy(ctx, current, src.String(), dest.String())
	}
}

func CopyContents(args []CopyContentsArgs) error {
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
