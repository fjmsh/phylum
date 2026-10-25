package core

import (
	"errors"
	"io"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/abema/go-mp4"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type ResourceBindConflictResolution int32

const (
	ResourceBindConflictResolutionError     = ResourceBindConflictResolution(0) // Error if exists. ID and path preserved
	ResourceBindConflictResolutionEnsure    = ResourceBindConflictResolution(1) // Error if type mismatch. ID and path preserved
	ResourceBindConflictResolutionRename    = ResourceBindConflictResolution(2) // Auto rename new resource. ID preserved, path may change
	ResourceBindConflictResolutionOverwrite = ResourceBindConflictResolution(3) // Delete existing resource only if type mismatch (preserves props). Path preserved, ID may change
	ResourceBindConflictResolutionDelete    = ResourceBindConflictResolution(4) // Delete existing resource before creating. ID and path preserved
)

var boxTypeSoun = mp4.StrToBoxType("soun")

func CheckResourceNameInvalid(s string) bool {
	return s == "" || s == "." || s == ".." || strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}

func (f *FileSystem) Mkdir(path string, requestedID uuid.UUID, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	var res Resource
	err := f.runInTx(func(f txFileSystem) error {
		var err error
		res, err = f.Mkdir(path, requestedID, createParents, conflictResolution)
		return err
	})
	return res, err
}

func (f *FileSystem) CreateFileByPath(path string, requestedID, versionID uuid.UUID, in io.Reader, conflictResolution ResourceBindConflictResolution) (uuid.UUID, error) {
	parent, name, err := f.destParentNameFromPath(path, false)
	if err != nil {
		return uuid.Nil, err
	}

	if versionID == uuid.Nil {
		versionID, _ = uuid.NewV7()
	}

	if w, err := storage.DefaultBackend().Write(versionID.String(), in); err != nil {
		return uuid.Nil, err
	} else if mimeType, err := guessMimeType(w); err != nil {
		w.Delete()
		return uuid.Nil, err
	} else {
		err := f.runInTx(func(f txFileSystem) error {
			if r, err := f.createMemberResource(parent, name, requestedID, false, conflictResolution); err != nil {
				return err
			} else {
				// ID could be different if we're overwriting an existing resource
				requestedID = r.id
				v := r.LatestVersion()
				if v.Created != 0 && v.SHA256 == w.SHA256Sum() && v.Size == w.Size() {
					return ErrDuplicateVersion
				}
			}

			if err := insertResourceVersion(f.db, requestedID, versionID, w.Size(), mimeType, w.SHA256Sum()); err != nil {
				return err
			}
			if err := updateResourceModified(f.db, requestedID); err != nil {
				return err
			}
			if err := jobs.GenerateImgs(f.db, versionID); err != nil {
				return err
			}
			return jobs.MigrateVersionContents(f.db, versionID)
		})
		if err != nil {
			w.Delete()
		}
		if errors.Is(err, ErrDuplicateVersion) {
			err = nil
		}
		return requestedID, err
	}
}

func (f *FileSystem) CreateFileVersion(r Resource, versionID uuid.UUID, in io.Reader) error {
	if err := r.checkPermission(ResourcePermissionWrite); err != nil {
		return err
	}
	if r.deleted.Valid {
		return ErrResourceDeleted
	}
	if versionID == uuid.Nil {
		versionID, _ = uuid.NewV7()
	}

	if w, err := storage.DefaultBackend().Write(versionID.String(), in); err != nil {
		return err
	} else if mimeType, err := guessMimeType(w); err != nil {
		w.Delete()
		return err
	} else {
		err = f.db.RunInTx(func(db db.TxHandler) error {
			if err := insertResourceVersion(db, r.id, versionID, w.Size(), mimeType, w.SHA256Sum()); err != nil {
				return err
			}
			if err := updateResourceModified(db, r.id); err != nil {
				return err
			}

			if err := jobs.GenerateImgs(db, versionID); err != nil {
				return err
			}
			return jobs.MigrateVersionContents(db, versionID)
		})
		if err != nil {
			w.Delete()
		}
		return err
	}
}

func (f txFileSystem) Mkdir(path string, requestedID uuid.UUID, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if requestedID == uuid.Nil {
		requestedID, _ = uuid.NewV7()
	}

	if !createParents {
		if parent, name, err := f.destParentNameFromPath(path, false); err != nil {
			return Resource{}, err
		} else {
			return f.createMemberResource(parent, name, requestedID, true, conflictResolution)
		}
	}

	var root uuid.UUID
	var err error
	if root, path, err = f.parsePathRoot(path); err != nil {
		return Resource{}, err
	}
	r, err := f.ResourceByID(root)

	segments := strings.Split(strings.TrimRight(strings.TrimLeft(path, "/"), "/"), "/")
	var resourceID uuid.UUID
	for i, name := range segments {
		if err != nil {
			return Resource{}, err
		}
		conflict := ResourceBindConflictResolutionEnsure
		if i == len(segments)-1 {
			resourceID = requestedID
			conflict = conflictResolution
		}
		r, err = f.createMemberResource(r, name, resourceID, true, conflict)
	}

	return r, err
}

func (f txFileSystem) createMemberResource(parent Resource, name string, requestedID uuid.UUID, dir bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if err := parent.checkPermission(ResourcePermissionWrite); err != nil {
		return Resource{}, err
	}
	if parent.deleted.Valid {
		return Resource{}, ErrResourceDeleted
	}
	if !parent.Dir() {
		return Resource{}, ErrResourceNotCollection
	}
	if CheckResourceNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}

	var res Resource
	var created bool
	var err error
	if res, created, _, err = f.resolveConflictAndInsertResource(requestedID, parent, name, dir, parent.permissions, conflictResolution); err != nil {
		return Resource{}, err
	} else if created {
		if err := recomputePermissions(f.db, res.id); err != nil {
			return Resource{}, err
		}
		if err := updateResourceModified(f.db, parent.id); err != nil {
			return Resource{}, err
		}
	}

	return res, nil
}

// resolveConflictAndInsertResource tries to insert a resource with the
// provided details if there isn't a name conflict. If there is one, then what
// happens depends on [conflictResolution].
//
// [ResourceBindConflictResolutionError] returns [ErrResourceNameConcflict]
//
// [ResourceBindConflictResolutionEnsure] returns the existing resource if
// [dir] matches. Returns [ErrResourceNameConflict] otherwise
//
// [ResourceBindConflictResolutionRename] finds the first available numbered
// suffix and creates that instead
//
// [ResourceBindConflictResolutionOverwrite] returns existing resource if [dir]
// matches after deleting children in case [dir] is `true`. If not, then
// deletes the existing resource and creates a new one.
//
// [ResourceBindConflictResolutionDelete] deletes the existing resource and
// creates a new one.
func (f txFileSystem) resolveConflictAndInsertResource(
	requestedID uuid.UUID,
	parent Resource,
	name string,
	dir bool,
	permissions []byte,
	conflictResolution ResourceBindConflictResolution,
) (res Resource, created bool, deleted bool, err error) {
	switch conflictResolution {
	case ResourceBindConflictResolutionError:
		var rID uuid.UUID
		if rID, _, err = childResourceIDByName(f.db, parent.id, name); err == nil {
			if rID == requestedID {
				res, err = f.resourceByID(rID)
				res.visibleParent = pgtype.UUID{Bytes: parent.id, Valid: true}
				res.inheritedPermissions = permissions
				res.permissions = permissions
				return res, true, false, err
			} else {
				return Resource{}, false, false, ErrResourceNameConflict
			}
		} else {
			// There is no name conflict. Proceed as usual
			err = nil
		}
	case ResourceBindConflictResolutionEnsure:
		var rID uuid.UUID
		var rDir bool
		if rID, rDir, err = childResourceIDByName(f.db, parent.id, name); err == nil {
			if rDir == dir {
				// Return the existing resourc
				res, err := f.resourceByID(rID)
				res.visibleParent = pgtype.UUID{Bytes: parent.id, Valid: true}
				res.inheritedPermissions = permissions
				res.permissions = permissions
				return res, false, false, err
			} else {
				return Resource{}, false, false, ErrResourceNameConflict
			}
		} else {
			// There is no name conflict. Proceed as usual
			err = nil
		}
	case ResourceBindConflictResolutionRename:
		name, err = detectNameConflict(f.db, parent.id, name, true)
	case ResourceBindConflictResolutionOverwrite:
		var rID uuid.UUID
		var rDir bool
		if rID, rDir, err = childResourceIDByName(f.db, parent.id, name); err == nil {
			if rDir == dir {
				if dir {
					err = softDeleteChildren(f.db, rID, parent.id)
				}
				if err == nil {
					res, err := f.resourceByID(rID)
					res.visibleParent = pgtype.UUID{Bytes: parent.id, Valid: true}
					res.inheritedPermissions = permissions
					res.permissions = permissions
					return res, false, true, err
				}
			} else {
				deleted = true
				err = softDelete(f.db, rID)
			}
		} else {
			// There is no name conflict. Proceed as usual
			err = nil
		}
	case ResourceBindConflictResolutionDelete:
		var rID uuid.UUID
		if rID, _, err = childResourceIDByName(f.db, parent.id, name); err == nil {
			deleted = true
			err = softDelete(f.db, rID)
		} else {
			// There is no name conflict. Proceed as usual
			err = nil
		}
	}

	if err != nil {
		return Resource{}, false, false, err
	}
	res, err = insertResource(
		f.db,
		requestedID,
		parent.id,
		name,
		dir,
		permissions,
	)
	return res, true, deleted, err
}

func insertResource(db db.TxHandler, id, parent uuid.UUID, name string, dir bool, permissions []byte) (Resource, error) {
	if id == uuid.Nil {
		id, _ = uuid.NewV7()
	}
	query, args, _ := pg.From("resources").
		Insert().
		Rows(goqu.Record{
			"id":          goqu.V(id),
			"parent":      goqu.V(parent),
			"name":        goqu.V(name),
			"dir":         goqu.V(dir),
			"permissions": goqu.V(permissions),
		}).
		Returning(
			"*",
			goqu.L("'[]'::JSONB"), // versions
			goqu.L("'[]'::JSONB"), // links
		).
		ToSQL()

	if rows, err := db.Query(query, args...); err != nil {
		return Resource{}, err
	} else if r, err := collectSimpleResource(rows); err != nil {
		if strings.Contains(err.Error(), "unique_member_resource_name") {
			err = ErrResourceNameConflict
		}
		if strings.Contains(err.Error(), "resources_pkey") {
			// maybe the request already succeeded in the previous attempt but the client didn't receive the response?
			err = ErrIDConflict
		}
		return Resource{}, err
	} else {
		r.parentID = pgtype.UUID{Bytes: parent, Valid: true}
		r.visibleParent = r.parentID
		r.inheritedPermissions = permissions
		r.permissions = permissions
		return r, nil
	}
}

func updateResourceModified(db db.TxHandler, id uuid.UUID) error {
	const q = "UPDATE resources SET modified = NOW() WHERE id = $1"
	_, err := db.Exec(q, id)
	return err
}

func insertResourceVersion(db db.TxHandler, id, versionID uuid.UUID, size int64, mimeType, sha256 string) error {
	const q = `WITH ins AS (
	INSERT INTO resource_versions(id, resource_id, size, mime_type, sha256, storage)
	VALUES (@version_id, @resource_id, @size, @mime_type, @sha256, @storage)
    ON CONFLICT (id) DO NOTHING
    RETURNING resource_id, size, sha256
)
SELECT resource_id, size, sha256 FROM ins
UNION ALL
SELECT resource_id, size, sha256 FROM resource_versions
WHERE id = @version_id
AND NOT EXISTS (SELECT 1 FROM ins)`

	args := pgx.NamedArgs{
		"resource_id": id,
		"version_id":  versionID,
		"size":        size,
		"mime_type":   mimeType,
		"sha256":      sha256,
		"storage":     storage.DefaultBackendName,
	}

	row := db.QueryRow(q, args)
	var rowResourceId pgtype.UUID
	var rowSize int64
	var rowSHA256 pgtype.Text
	if err := row.Scan(&rowResourceId, &rowSize, &rowSHA256); err != nil {
		return err
	}
	if id != rowResourceId.Bytes || size != rowSize || sha256 != rowSHA256.String {
		return ErrIDConflict
	}

	return nil
}

func insertResourcesFast(db db.TxHandler, arg []insertResourcesFastParams) (int64, error) {
	return db.CopyFrom([]string{"resources"}, []string{"id", "parent", "name", "dir"}, &iteratorForInsertResourcesFast{rows: arg})
}

// For bulk insert
type insertResourcesFastParams struct {
	ID     uuid.UUID
	Parent uuid.UUID
	Name   string
	Dir    bool
}

// iteratorForInsertResourcesFast implements pgx.CopyFromSource.
type iteratorForInsertResourcesFast struct {
	rows                 []insertResourcesFastParams
	skippedFirstNextCall bool
}

func (r *iteratorForInsertResourcesFast) Next() bool {
	if len(r.rows) == 0 {
		return false
	}
	if !r.skippedFirstNextCall {
		r.skippedFirstNextCall = true
		return true
	}
	r.rows = r.rows[1:]
	return len(r.rows) > 0
}

func (r iteratorForInsertResourcesFast) Values() ([]interface{}, error) {
	return []interface{}{
		r.rows[0].ID,
		r.rows[0].Parent,
		r.rows[0].Name,
		r.rows[0].Dir,
	}, nil
}

func (r iteratorForInsertResourcesFast) Err() error {
	return nil
}

func insertResourceVersionsFast(db db.TxHandler, arg []insertResourceVersionsFastParams) (int64, error) {
	return db.CopyFrom([]string{"resource_versions"}, []string{"id", "resource_id", "size", "mime_type", "sha256", "imgres", "storage", "pending"}, &iteratorForInsertResourceVersionsFast{rows: arg})
}

// For bulk insert
type insertResourceVersionsFastParams struct {
	ID         uuid.UUID
	ResourceID uuid.UUID
	Size       int64
	MimeType   string
	SHA256     string
	ImgRes     uint8
}

// iteratorForInsertResourceVersionsFast implements pgx.CopyFromSource.
type iteratorForInsertResourceVersionsFast struct {
	rows                 []insertResourceVersionsFastParams
	skippedFirstNextCall bool
}

func (r *iteratorForInsertResourceVersionsFast) Next() bool {
	if len(r.rows) == 0 {
		return false
	}
	if !r.skippedFirstNextCall {
		r.skippedFirstNextCall = true
		return true
	}
	r.rows = r.rows[1:]
	return len(r.rows) > 0
}

func (r iteratorForInsertResourceVersionsFast) Values() ([]interface{}, error) {
	return []interface{}{
		r.rows[0].ID,
		r.rows[0].ResourceID,
		r.rows[0].Size,
		r.rows[0].MimeType,
		r.rows[0].SHA256,
		r.rows[0].ImgRes,
		storage.DefaultBackendName,
		true,
	}, nil
}

func (r iteratorForInsertResourceVersionsFast) Err() error {
	return nil
}
