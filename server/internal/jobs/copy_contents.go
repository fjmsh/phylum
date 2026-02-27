package jobs

import (
	"context"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
)

type CopyContentsArgs struct {
	Src  uuid.UUID `json:"src"`
	Dest uuid.UUID `json:"dest"`
}

func (a CopyContentsArgs) Kind() string        { return "copy_contents" }
func (a CopyContentsArgs) Sequences() []string { return []string{a.Src.String(), a.Dest.String()} }
func (a CopyContentsArgs) Blocking() bool      { return true }

type CopyContentsWorker struct {
	steve.WorkerDefaults[CopyContentsArgs]
}

func (w *CopyContentsWorker) Work(ctx context.Context, job *steve.Job[CopyContentsArgs]) error {
	return copyContents(ctx, job.Args.Src, job.Args.Dest)
}

func copyContents(ctx context.Context, src, dest uuid.UUID) error {
	db := db.Get(ctx)
	destBackend := storage.DefaultBackend()
	if srcBackend, err := getCurrentStorage(db, src); err != nil {
		return errors.New("failed to get src storage: " + err.Error())
	} else {
		if err := destBackend.Copy(ctx, srcBackend, src.String(), dest.String()); err != nil {
			return errors.New("failed to copy contents: " + err.Error())
		}
		const q = "UPDATE resource_versions SET pending = FALSE WHERE id = $1::UUID"
		if _, err := db.Exec(q, dest); err != nil {
			destBackend.Delete(dest.String())
			return errors.New("failed to update db: " + err.Error())
		}
		return nil
	}
}

func CopyContents(db db.Handler, args []CopyContentsArgs) error {
	params := make([]steve.JobArgs, len(args))
	for i, a := range args {
		params[i] = a
	}
	return steve.Get().InsertJobs(db, params)
}
