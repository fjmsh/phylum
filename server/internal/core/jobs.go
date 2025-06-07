package core

import (
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
	"github.com/sirupsen/logrus"
)

func moveVersionToTargetBackend(db db.Handler, versionID uuid.UUID) {
	logrus.Info("Moving to Target Storage: " + versionID.String())
	if current, err := getCurrentStorage(db, versionID); err != nil {
		logrus.Warn("failed to get current storage for " + versionID.String() + ": " + err.Error())
	} else if target, err := findTargetStorageForVersion(db, versionID); err != nil {
		logrus.Warn("failed to find target storage for " + versionID.String() + ": " + err.Error())
	} else if err := target.Copy(versionID.String(), current); err != nil {
		logrus.Warn("failed to copy " + versionID.String() + ": " + err.Error())
	} else if err := updateStorage(db, versionID, target.Name()); err != nil {
		logrus.Warn("failed to update storage in DB for " + versionID.String() + ": " + err.Error())
		if err := target.Delete(versionID.String()); err != nil {
			logrus.Warn("failed to delete new copy for " + versionID.String() + ": " + err.Error())
		}
	} else if current.Delete(versionID.String()); err != nil {
		logrus.Warn("failed to delete old copy for " + versionID.String() + ": " + err.Error())
	}
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
