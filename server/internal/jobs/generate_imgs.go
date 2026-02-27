package jobs

import (
	"context"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/img"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

type GenerateImgsArgs struct {
	VersionID uuid.UUID `json:"versionID"`
}

func (a GenerateImgsArgs) Kind() string        { return "gen_imgs" }
func (a GenerateImgsArgs) Sequences() []string { return []string{a.VersionID.String()} }
func (a GenerateImgsArgs) Blocking() bool      { return false }
func (a GenerateImgsArgs) MaxAttempts() int    { return 3 }

type GenerateImgsWorker struct {
	steve.WorkerDefaults[GenerateImgsArgs]
}

func (w *GenerateImgsWorker) Work(ctx context.Context, job *steve.Job[GenerateImgsArgs]) error {
	logger := zerolog.Ctx(ctx)
	db := db.Get(ctx)
	mimeType, existingImgres, err := getResourceVersionMimeTypeImgres(db, job.Args.VersionID)
	if err != nil {
		return errors.New("Unable to read resource version info: " + err.Error())
	}
	generator := img.GetGenerator(mimeType)
	if generator == nil {
		return nil
	}
	if backend, err := getCurrentStorage(db, job.Args.VersionID); err != nil {
		return errors.New("Failed to get src storage: " + err.Error())
	} else if local, ok := backend.(storage.LocalBackend); ok {
		path := local.Path(job.Args.VersionID.String())
		if generated, err := generator(path); err != nil {
			return errors.New("Failed to generating imgs: " + err.Error())
		} else if err := updateResourceVersionImgres(db, job.Args.VersionID, generated); err != nil {
			return errors.New("Failed to update resource version: " + err.Error())
		} else if err := img.Delete(job.Args.VersionID.String(), existingImgres&(^generated)); err != nil {
			logger.Warn().Uint8("existing", existingImgres).Uint8("generated", generated).Msg("Failed to delete existing imgs")
		}
		return nil
	} else {
		return errors.New("Generating images from assets in remote storage is not currently supported")
	}
}

func GenerateImgs(db db.Handler, versionID uuid.UUID) error {
	return steve.Get().InsertJob(db, GenerateImgsArgs{VersionID: versionID})
}

func GenerateImgsMany(db db.Handler, args []GenerateImgsArgs) error {
	params := make([]steve.JobArgs, len(args))
	for i, a := range args {
		params[i] = a
	}
	return steve.Get().InsertJobs(db, params)
}

func getResourceVersionMimeTypeImgres(db db.Handler, id uuid.UUID) (mimeType string, imgres uint8, err error) {
	const q = "SELECT mime_type, imgres FROM resource_versions WHERE id = $1"
	row := db.QueryRow(q, id)
	err = row.Scan(&mimeType, &imgres)
	return
}

func updateResourceVersionImgres(db db.Handler, id uuid.UUID, imgres uint8) error {
	const q = "UPDATE resource_versions SET imgres = $2 WHERE id = $1"
	_, err := db.Exec(q, id, imgres)
	return err
}
