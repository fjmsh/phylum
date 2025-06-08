package core

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/storage"
)

type versionInfo struct {
	id      uuid.UUID
	storage string
}

func deleteAllVersionContents(db db.Handler, ids uuid.UUIDs) error {
	const q = `SELECT v.id, v.storage FROM resources r
JOIN resource_versions v ON r.id = v.resource_id
WHERE r.id = ANY ($1::UUID[])`
	if rows, err := db.Query(q, ids); err != nil {
		return err
	} else if versions, err := pgx.CollectRows(rows, scanDeletedVersion); err != nil {
		return err
	} else {
		return deleteVersionContents(versions)
	}
}

func deleteVersionContents(versions []versionInfo) error {
	idsPerBackend := make(map[string][]string)
	for _, v := range versions {
		idsPerBackend[v.storage] = append(idsPerBackend[v.storage], v.id.String())
	}
	for k, v := range idsPerBackend {
		if backend, err := storage.GetBackend(k); err != nil {
			return err
		} else {
			backend.DeleteAll(v)
		}
	}
	return nil
}

func scanDeletedVersion(row pgx.CollectableRow) (versionInfo, error) {
	var v versionInfo
	err := row.Scan(
		&v.id,
		&v.storage,
	)
	return v, err
}
