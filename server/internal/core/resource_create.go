package core

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/sirupsen/logrus"
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

func (f fileSystem) CreateResourceByPath(path string, id uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	var res Resource
	err := f.runInTx(func(f txFileSystem) error {
		var err error
		res, err = f.CreateResourceByPath(path, id, dir, createParents, conflictResolution)
		return err
	})
	return res, err
}

func (f txFileSystem) CreateResourceByPath(path string, id uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if id == uuid.Nil {
		id, _ = uuid.NewV7()
	}

	if !createParents {
		name, parent, err := f.targetNameParentByPathWithRoot(path, Resource{})
		if err != nil {
			if errors.Is(err, ErrResourceNotFound) {
				err = ErrParentNotFound
			}
			return Resource{}, err
		}
		return f.createMemberResource(parent, name, id, dir, conflictResolution)
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
			resourceID = id
			conflict = conflictResolution
		}
		r, err = f.createMemberResource(r, s, resourceID, d, conflict)
	}

	return r, err
}

func (f txFileSystem) createMemberResource(r Resource, name string, id uuid.UUID, dir bool, conflictResolution ResourceBindConflictResolution) (Resource, error) {
	if r.deleted.Valid {
		return Resource{}, ErrResourceDeleted
	}
	if !r.Dir() {
		return Resource{}, ErrResourceNotCollection
	}
	if err := r.checkPermission(f.user, PermissionWrite); err != nil {
		return Resource{}, err
	}
	if CheckResourceNameInvalid(name) {
		return Resource{}, ErrResourceNameInvalid
	}
	if id == uuid.Nil {
		id, _ = uuid.NewV7()
	}
	var res Resource
	var created bool
	var err error
	if res, created, _, err = createResource(f.db, id, r.id, name, dir, r.permissions, conflictResolution); err != nil {
		if errors.Is(err, ErrResourceIDConflict) {
			return resourceByID(f.db, id, f.user.ID)
		}
		return Resource{}, err
	} else if created {
		if err := recomputePermissions(f.db, id); err != nil {
			return Resource{}, err
		}
		if err := updateResourceModified(f.db, r.id); err != nil {
			return Resource{}, err
		}
	}

	return res, nil
}

func createResource(
	db db.TxHandler,
	id uuid.UUID,
	parent uuid.UUID,
	name string,
	dir bool,
	permissions []byte,
	conflictResolution ResourceBindConflictResolution,
) (res Resource, created, deleted bool, err error) {
	if name, err = detectNameConflict(db, parent, name, conflictResolution == ResourceBindConflictResolutionRename); err != nil {
		// Name conflicts will be handled outside of this if-block
		if !errors.Is(err, ErrResourceNameConflict) {
			return
		}
	} else {
		// No name conflict. Just insert and move along
		res, err = insertResource(
			db,
			id,
			parent,
			name,
			dir,
			permissions,
		)
		created = true
		// maybe the request already succeeded in the previous attempt but the client didn't receive the response?
		if strings.Contains(err.Error(), "resources_pkey") {
			err = ErrResourceIDConflict
		}
		return
	}

	switch conflictResolution {
	case ResourceBindConflictResolutionError:
		err = ErrResourceNameConflict
	case ResourceBindConflictResolutionEnsure:
		var rDir bool
		_, rDir, err = childResourceIDByName(db, parent, name)
		if err == nil && rDir != dir {
			err = ErrResourceNameConflict
		}
	case ResourceBindConflictResolutionRename:
		logrus.Warn("Rename case reached?!")
		// This case is should already be handled above
	case ResourceBindConflictResolutionOverwrite:
		var rID uuid.UUID
		var rDir bool
		rID, rDir, err = childResourceIDByName(db, parent, name)
		if err == nil {
			deleted = true
			if rDir == dir {
				if dir {
					err = softDeleteChildren(db, rID, parent)
				}
				if err == nil {
					// Repurpose existing resource
					res, err = resourceByID(db, rID, -1)
					// This is set from the query using the user id, which we passed in as '-1' above.
					res.visibleParent = pgtype.UUID{Bytes: parent, Valid: true}
				}
			} else {
				err = softDelete(db, res.id)
				if err == nil {
					res, created, _, err = createResource(
						db,
						id,
						parent,
						name,
						dir,
						permissions,
						ResourceBindConflictResolutionError,
					)
				}
			}
		}
	case ResourceBindConflictResolutionDelete:
		var rID uuid.UUID
		rID, _, err = childResourceIDByName(db, parent, name)
		if err == nil {
			deleted = true
			err = softDelete(db, rID)
			if err == nil {
				res, created, _, err = createResource(
					db,
					id,
					parent,
					name,
					dir,
					permissions,
					ResourceBindConflictResolutionError,
				)
			}
		}
	}
	return
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
	} else {
		r, err := collectFullResource(rows)
		r.parentID = pgtype.UUID{Bytes: parent, Valid: true}
		r.visibleParent = r.parentID
		r.inheritedPermissions = permissions
		r.permissions = permissions
		return r, err
	}
}

func updateResourceModified(db db.TxHandler, id uuid.UUID) error {
	const q = "UPDATE resources SET modified = NOW() WHERE id = $1"
	_, err := db.Exec(q, id)
	return err
}

func createResourceVersion(db db.TxHandler, id, versionID uuid.UUID, size int64, mimeType, sha256 string) error {
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

// TODO: Make not public
func createResources(db db.TxHandler, arg []CreateResourcesParams) (int64, error) {
	return db.CopyFrom([]string{"resources"}, []string{"id", "parent", "name", "dir"}, &iteratorForCreateResources{rows: arg})
}

// For bulk insert
type CreateResourcesParams struct {
	ID     uuid.UUID
	Parent uuid.UUID
	Name   string
	Dir    bool
}

// iteratorForCreateResources implements pgx.CopyFromSource.
type iteratorForCreateResources struct {
	rows                 []CreateResourcesParams
	skippedFirstNextCall bool
}

func (r *iteratorForCreateResources) Next() bool {
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

func (r iteratorForCreateResources) Values() ([]interface{}, error) {
	return []interface{}{
		r.rows[0].ID,
		r.rows[0].Parent,
		r.rows[0].Name,
		r.rows[0].Dir,
	}, nil
}

func (r iteratorForCreateResources) Err() error {
	return nil
}
