package jobs

import (
	"context"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

type MigrateArgs struct {
	VersionID uuid.UUID `json:"version_id"`
}

func (a MigrateArgs) Kind() string        { return "migrate" }
func (a MigrateArgs) Sequences() []string { return []string{a.VersionID.String()} }
func (a MigrateArgs) Blocking() bool      { return false }
func (a MigrateArgs) MaxAttempts() int    { return 3 }

type MigrateWorker struct {
	steve.WorkerDefaults[MigrateArgs]
}

func (w *MigrateWorker) Work(ctx context.Context, job *steve.Job[MigrateArgs]) error {
	return migrateVersionContents(ctx, job.Args.VersionID)
}

func MigrateContentsMany(db db.Handler, args []MigrateArgs) error {
	params := make([]steve.JobArgs, len(args))
	for i, a := range args {
		params[i] = a
	}
	return steve.Get().InsertJobs(db, params)
}

func MigrateVersionContents(db db.Handler, versionID uuid.UUID) error {
	return steve.Get().InsertJob(db, MigrateArgs{VersionID: versionID})
}

func migrateVersionContents(ctx context.Context, versionID uuid.UUID) error {
	db := db.Get(ctx)
	if current, err := getCurrentStorage(db, versionID); err != nil {
		return errors.New("failed to get current storage: " + err.Error())
	} else if target, err := findTargetStorageForVersion(db, versionID); err != nil {
		return errors.New("failed to find target storage: " + err.Error())
	} else if current.Name() == target.Name() {
		return nil
	} else if err := target.Copy(ctx, current, versionID.String(), versionID.String()); err != nil {
		return errors.New("failed to copy to target storage: " + err.Error())
	} else if err := updateStorage(db, versionID, target.Name()); err != nil {
		if err := target.Delete(versionID.String()); err != nil {
			zerolog.Ctx(ctx).Warn().Err(err).Msg("failed to delete new copy")
		}
		return errors.New("failed to update storage in db: " + err.Error())
	} else if err := current.Delete(versionID.String()); err != nil {
		return errors.New("failed to delete old copy: " + err.Error())
	}
	return nil
}

func getCurrentStorage(db db.Handler, versionID uuid.UUID) (storage.Backend, error) {
	q := "SELECT storage FROM resource_versions WHERE id = $1::UUID"
	var s string
	row := db.QueryRow(q, versionID)
	if err := row.Scan(&s); err != nil {
		return nil, err
	}
	return storage.GetBackend(s)
}

func findTargetStorageForVersion(db db.Handler, versionID uuid.UUID) (storage.Backend, error) {
	q := `WITH RECURSIVE nodes(id, parent, storage) AS (
SELECT r.id, r.parent, s.storage
	FROM resources r
	LEFT JOIN storage_mounts s
	ON r.id = s.id
	WHERE r.id = (SELECT resource_id FROM resource_versions WHERE id = $1::UUID)
UNION ALL
	SELECT r.id, r.parent, COALESCE(n.storage, s.storage)
		FROM resources r
		LEFT JOIN storage_mounts s ON r.id = s.id
		JOIN nodes n ON r.id = n.parent
) SELECT COALESCE(storage, '_') from nodes n WHERE n.parent IS NULL`

	row := db.QueryRow(q, versionID)
	var s string
	if err := row.Scan(&s); err != nil {
		return nil, err
	} else if s != "" {
		return storage.GetBackend(s)
	}
	return storage.DefaultBackend(), nil
}

func updateStorage(d db.Handler, versionID uuid.UUID, storage string) error {
	q := "UPDATE resource_versions SET storage = $2::TEXT WHERE id = $1::UUID"
	return d.RunInTx(func(db db.TxHandler) error {
		_, err := db.Exec(q, versionID, storage)
		return err
	})
}
