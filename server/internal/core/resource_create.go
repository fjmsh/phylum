package core

import (
	"encoding/hex"
	"errors"
	"hash"
	"io"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type ResourceBindConflictResolution int32

const (
	ResourceBindConflictResolutionError     = ResourceBindConflictResolution(0) // Error if exists
	ResourceBindConflictResolutionEnsure    = ResourceBindConflictResolution(1) // Error if type mismatch
	ResourceBindConflictResolutionRename    = ResourceBindConflictResolution(2) // Auto rename new resource
	ResourceBindConflictResolutionOverwrite = ResourceBindConflictResolution(3) // Delete existing resource only if type mismatch (preserves props)
	ResourceBindConflictResolutionDelete    = ResourceBindConflictResolution(4) // Delete existing resource before creating
)

func CheckResourceNameInvalid(s string) bool {
	return s == "" || s == "." || s == ".." || strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}

func (f fileSystem) CreateResourceByPath(path string, requestedID uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	var res Resource
	err := f.runInTx(func(f txFileSystem) error {
		var err error
		res, err = f.CreateResourceByPath(path, requestedID, dir, createParents, conflictResolution)
		return err
	})
	return res, err
}

func (f fileSystem) CreateFileByPath(path string, requestedID, versionID uuid.UUID, conflictResolution ResourceBindConflictResolution) (io.WriteCloser, error) {
	name, parent, err := f.targetByPathWithRoot(path, Resource{})
	if err != nil {
		if errors.Is(err, ErrResourceNotFound) {
			err = ErrParentNotFound
		}
		return nil, err
	}
	if parent.deleted.Valid {
		return nil, ErrParentNotFound
	}

	if err := parent.checkPermission(f.user, PermissionWrite); err != nil {
		return nil, err
	}
	if versionID == uuid.Nil {
		versionID, _ = uuid.NewV7()
	}

	// return f.createMemberResource(parent, name, id, dir, conflictResolution)
	if dest, err := storage.DefaultBackend().OpenWrite(versionID.String()); err != nil {
		return nil, err
	} else {
		return computeProps(dest, func(len int, hash hash.Hash, mimeType string) error {
			sum := hex.EncodeToString(hash.Sum(nil))
			err := f.runInTx(func(f txFileSystem) error {
				if r, err := f.createMemberResource(parent, name, requestedID, false, conflictResolution); err != nil {
					return err
				} else {
					// ID could be different if we're overwriting an existing resource
					requestedID = r.id
				}

				if err := insertResourceVersion(f.db, requestedID, versionID, int64(len), mimeType, sum); err != nil {
					return err
				}
				if err := updateResourceModified(f.db, requestedID); err != nil {
					return err
				}

				// TODO: #jobs #tx pass in transaction
				return jobs.MigrateVersionContents(versionID)
			})
			if err != nil {
				storage.DefaultBackend().Delete(versionID.String())
			}
			return err
		}), nil
	}
}

func (f fileSystem) CreateFileVersion(r Resource, versionID uuid.UUID) (io.WriteCloser, error) {
	if err := r.checkPermission(f.user, PermissionWrite); err != nil {
		return nil, err
	}
	if r.deleted.Valid {
		return nil, ErrResourceDeleted
	}
	if versionID == uuid.Nil {
		versionID, _ = uuid.NewV7()
	}

	if dest, err := storage.DefaultBackend().OpenWrite(versionID.String()); err != nil {
		return nil, err
	} else {
		return computeProps(dest, func(len int, hash hash.Hash, mimeType string) error {
			sum := hex.EncodeToString(hash.Sum(nil))
			err := f.db.RunInTx(func(db db.TxHandler) error {
				if err := insertResourceVersion(db, r.id, versionID, int64(len), mimeType, sum); err != nil {
					return err
				}
				if err := updateResourceModified(db, r.id); err != nil {
					return err
				}

				// TODO: #jobs #tx pass in transaction
				return jobs.MigrateVersionContents(versionID)
			})
			if err != nil {
				storage.DefaultBackend().Delete(versionID.String())
			}
			return err
		}), nil
	}
}

func (f txFileSystem) CreateResourceByPath(path string, requestedID uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if requestedID == uuid.Nil {
		requestedID, _ = uuid.NewV7()
	}

	if !createParents {
		name, parent, err := f.targetByPathWithRoot(path, Resource{})
		if err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, err
		}
		if parent.deleted.Valid {
			return Resource{}, ErrParentNotFound
		}
		return f.createMemberResource(parent, name, requestedID, dir, conflictResolution)
	}

	root, path, err := parseUUIDPrefix(path)
	if err != nil {
		return Resource{}, ErrResourcePathInvalid
	}
	if root.Valid {
		f.fileSystem = f.fileSystem.withPathRoot(root)
	}
	segments := strings.Split(strings.TrimRight(strings.TrimLeft(path, "/"), "/"), "/")
	r, err := f.ResourceByID(f.pathRoot.Bytes)
	for i, s := range segments {
		if err != nil {
			return Resource{}, err
		}
		d := true
		resourceID, _ := uuid.NewV7()
		conflict := ResourceBindConflictResolutionEnsure
		if i == len(segments)-1 {
			d = dir
			resourceID = requestedID
			conflict = conflictResolution
		}
		r, err = f.createMemberResource(r, s, resourceID, d, conflict)
	}

	return r, err
}

func (f txFileSystem) createMemberResource(r Resource, name string, requestedID uuid.UUID, dir bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if r.deleted.Valid {
		return Resource{}, ErrResourceDeleted
	}
	if !r.Dir() {
		return Resource{}, ErrResourceNotCollection
	}
	if CheckResourceNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}
	if requestedID == uuid.Nil {
		requestedID, _ = uuid.NewV7()
	}
	var res Resource
	var created bool
	var err error
	if res, created, _, err = resolveConflictAndInsertResource(f.db, requestedID, r.id, name, dir, r.permissions, conflictResolution); err != nil {
		if errors.Is(err, ErrResourceIDConflict) {
			return resourceByID(f.db, requestedID, f.user.ID)
		}
		return Resource{}, err
	} else if created {
		if err := r.checkPermission(f.user, PermissionWrite); err != nil {
			return Resource{}, err
		}
		if err := recomputePermissions(f.db, requestedID); err != nil {
			return Resource{}, err
		}
		if err := updateResourceModified(f.db, r.id); err != nil {
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
func resolveConflictAndInsertResource(
	db db.TxHandler,
	requestedID uuid.UUID,
	parent uuid.UUID,
	name string,
	dir bool,
	permissions []byte,
	conflictResolution ResourceBindConflictResolution,
) (res Resource, created bool, deleted bool, err error) {
	switch conflictResolution {
	case ResourceBindConflictResolutionError:
		// Nothing to do. We will try inserting below, and fail in case of name conflict
	case ResourceBindConflictResolutionEnsure:
		var rID uuid.UUID
		var rDir bool
		if rID, rDir, err = childResourceIDByName(db, parent, name); err == nil {
			if rDir == dir {
				// Return the existing resourc
				res, err := resourceByID(db, rID, -1)
				res.visibleParent = pgtype.UUID{Bytes: parent, Valid: true}
				return res, false, false, err
			} else {
				return Resource{}, false, false, ErrResourceNameConflict
			}
		} else {
			// There is no name conflict. Proceed as usual
			err = nil
		}
	case ResourceBindConflictResolutionRename:
		name, err = detectNameConflict(db, parent, name, true)
	case ResourceBindConflictResolutionOverwrite:
		var rID uuid.UUID
		var rDir bool
		if rID, rDir, err = childResourceIDByName(db, parent, name); err == nil {
			if rDir == dir {
				if dir {
					err = softDeleteChildren(db, rID, parent)
				}
				if err == nil {
					res, err := resourceByID(db, rID, -1)
					res.visibleParent = pgtype.UUID{Bytes: parent, Valid: true}
					return res, false, true, err
				}
			} else {
				deleted = true
				err = softDelete(db, rID)
			}
		}
	case ResourceBindConflictResolutionDelete:
		var rID uuid.UUID
		if rID, _, err = childResourceIDByName(db, parent, name); err != nil {
			deleted = true
			err = softDelete(db, rID)
		}
	}
	if err != nil {
		return Resource{}, false, false, err
	}
	res, err = insertResource(
		db,
		requestedID,
		parent,
		name,
		dir,
		permissions,
	)
	return res, true, deleted, err
}

func insertResource(db db.TxHandler, id, parent uuid.UUID, name string, dir bool, permissions []byte) (Resource, error) {
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
			goqu.L("NULL"),        // visible parent
			goqu.L("'{}'::JSONB"), // inherited permissions
		).
		ToSQL()

	if rows, err := db.Query(query, args...); err != nil {
		return Resource{}, err
	} else if r, err := collectFullResource(rows); err != nil {
		if strings.Contains(err.Error(), "unique_member_resource_name") {
			err = ErrResourceNameConflict
		}
		if strings.Contains(err.Error(), "resources_pkey") {
			// maybe the request already succeeded in the previous attempt but the client didn't receive the response?
			err = ErrResourceIDConflict
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
	const q = `INSERT INTO resource_versions(id, resource_id, size, mime_type, sha256, storage)
	VALUES (@version_id::UUID, @resource_id::UUID, @size::INT, @mime_type::TEXT, @sha256::TEXT, @storage::TEXT)`

	args := pgx.NamedArgs{
		"resource_id": id,
		"version_id":  versionID,
		"size":        size,
		"mime_type":   mimeType,
		"sha256":      sha256,
		"storage":     storage.DefaultBackendName,
	}
	_, err := db.Exec(q, args)
	return err
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
	return db.CopyFrom([]string{"resource_versions"}, []string{"id", "resource_id", "size", "mime_type", "sha256", "storage"}, &iteratorForInsertResourceVersionsFast{rows: arg})
}

// For bulk insert
type insertResourceVersionsFastParams struct {
	ID         uuid.UUID
	ResourceID uuid.UUID
	Size       int32
	MimeType   string
	SHA256     string
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
		storage.DefaultBackendName,
	}, nil
}

func (r iteratorForInsertResourceVersionsFast) Err() error {
	return nil
}
