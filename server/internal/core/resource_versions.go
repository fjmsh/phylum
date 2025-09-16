package core

import (
	"encoding/json"
	"errors"
	"slices"
	"time"

	"codeberg.org/shroff/phylum/server/internal/img"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f *FileSystem) GetVersion(r Resource, versionIDStr string) (Version, error) {
	versionID := r.latestVersionInfo.ID
	if versionIDStr != "" {
		var err error
		versionID, err = uuid.Parse(versionIDStr)
		if err != nil {
			return Version{}, err
		}
	}

	const q = `SELECT id, created, size, mime_type, sha256, storage, imgres FROM resource_versions
WHERE resource_id = $1::UUID
AND id = $2::UUID
AND DELETED IS NULL`

	row := f.db.QueryRow(q, r.id, versionID)
	var v Version
	var created time.Time
	err := row.Scan(&v.ID, &created, &v.Size, &v.MimeType, &v.SHA256, &v.Storage, &v.ImgRes)
	if err != nil {
		if Is(err, pgx.ErrNoRows) {
			return v, ErrVersionNotFound
		} else {
			return v, errors.New("failed to get resource version: " + err.Error())
		}
	}
	v.Created = int(created.Unix())
	return v, nil
}

func (f *FileSystem) GetAllVersions(r Resource) ([]Version, error) {
	const q = `SELECT id, created, deleted, size, mime_type, sha256, storage, imgres FROM resource_versions
WHERE resource_id = $1::UUID
ORDER BY created DESC`
	if rows, err := f.db.Query(q, r.id); err != nil {
		return nil, errors.New("failed to get resource versions: " + err.Error())
	} else {
		return pgx.CollectRows(rows, scanVersion)
	}
}

func (f *FileSystem) DeleteResourceVersion(res Resource, versionID uuid.UUID) (Resource, error) {
	if err := f.checkPermission(res, PermissionWrite); err != nil {
		return res, err
	}

	versions := make([]VersionInfo, 0, 1)
	err := json.Unmarshal(res.versions, &versions)
	if err != nil {
		return res, err
	}
	i := slices.IndexFunc(versions, func(v VersionInfo) bool {
		return v.ID == versionID
	})
	if i == 0 {
		return res, ErrResourceVersionLatest
	}
	versions[i].Deleted = int(time.Now().Unix())
	res.versions, _ = json.Marshal(versions)

	const q = "UPDATE resource_versions SET deleted = CURRENT_TIMESTAMP WHERE id = $1::UUID RETURNING storage, imgres"
	err = f.runInTx(func(f txFileSystem) error {
		row := f.db.QueryRow(q, versionID)
		var storage string
		var imgRes img.Res
		if err := row.Scan(&storage, &imgRes); err != nil {
			return err
		}

		if err := updateResourceModified(f.db, res.id); err != nil {
			return err
		}
		res.modified = time.Now()
		return jobs.DeleteContents(f.db, []jobs.DeleteContentsArgs{{
			Name:    versionID.String(),
			Storage: storage,
			ImgRes:  imgRes,
		}})
	})

	return res, err
}
