package jobs

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/riverqueue/river"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

type MigrateArgs struct {
	VersionID uuid.UUID `json:"version_id"`
}

func (MigrateArgs) Kind() string { return "migrate" }

type MigrateWorker struct {
	river.WorkerDefaults[MigrateArgs]
}

func (w *MigrateWorker) Work(ctx context.Context, job *river.Job[MigrateArgs]) error {
	return migrateVersionContents(db.Get(ctx), job.Args.VersionID)
}

func MigrateVersionContents(versionID uuid.UUID) {
	client.Insert(context.Background(), MigrateArgs{VersionID: versionID}, &river.InsertOpts{})
}

func migrateVersionContents(db db.Handler, versionID uuid.UUID) error {
	if current, err := getCurrentStorage(db, versionID); err != nil {
		return errors.New("failed to get current storage: " + err.Error())
	} else if target, err := findTargetStorageForVersion(db, versionID); err != nil {
		return errors.New("failed to find target storage: " + err.Error())
	} else if current.Name() == target.Name() {
		return nil
	} else if err := target.Copy(versionID.String(), current); err != nil {
		return errors.New("failed to copy to target storage: " + err.Error())
	} else if err := updateStorage(db, versionID, target.Name()); err != nil {
		if err := target.Delete(versionID.String()); err != nil {
			logrus.Warn("failed to delete new copy: " + err.Error())
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
	LEFT JOIN resource_storage s
	ON r.id = s.id
	WHERE r.id = (SELECT resource_id FROM resource_versions WHERE id = $1::UUID)
UNION ALL
	SELECT r.id, r.parent, COALESCE(n.storage, s.storage)
		FROM resources r
		LEFT JOIN resource_storage s ON r.id = s.id
		JOIN nodes n ON r.id = n.parent
) SELECT storage from nodes n WHERE n.parent IS NULL;
 `

	row := db.QueryRow(q, versionID)
	var s string
	if err := row.Scan(&s); err != nil {
		return nil, err
	} else if s != "" {
		return storage.GetBackend(s)
	}
	return storage.DefaultBackend(), nil
}

func updateStorage(db db.Handler, versionID uuid.UUID, storage string) error {
	q := "UPDATE resource_versions SET storage = $2::TEXT WHERE id = $1::UUID"
	_, err := db.Exec(q, versionID, storage)
	return err
}
