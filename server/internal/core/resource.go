package core

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type Resource struct {
	id                   uuid.UUID
	parentID             pgtype.UUID
	name                 string
	dir                  bool
	created              time.Time
	modified             time.Time
	deleted              pgtype.Timestamp
	permissions          []byte
	grants               []byte
	versions             []byte
	links                []byte
	inheritedPermissions []byte
	visibleParent        pgtype.UUID
	latestVersionInfo    VersionInfo
}

func (r Resource) ID() uuid.UUID                { return r.id }
func (r Resource) Name() string                 { return r.name }
func (r Resource) Dir() bool                    { return r.dir }
func (r Resource) Created() time.Time           { return r.created }
func (r Resource) Modified() time.Time          { return r.modified }
func (r Resource) Deleted() pgtype.Timestamp    { return r.deleted }
func (r Resource) Grants() []byte               { return r.grants }
func (r Resource) Versions() []byte             { return r.versions }
func (r Resource) Links() []byte                { return r.links }
func (r Resource) VisibleParentID() pgtype.UUID { return r.visibleParent }
func (r Resource) InheritedPermissions() []byte { return r.inheritedPermissions }
func (r Resource) LatestVersion() VersionInfo   { return r.latestVersionInfo }

func (r Resource) userPermission(user User) (Permission, error) {
	if user.hasPermission(PermissionFilesAll) {
		return -1, nil
	}

	return readPermissionFromJson(r.permissions, user.ID)
}

func (r Resource) checkPermission(user User, p Permission) error {
	if up, err := r.userPermission(user); err != nil {
		return err
	} else if up&p == 0 {
		return ErrInsufficientPermissions
	}
	return nil
}

func collectFullResource(rows pgx.Rows) (Resource, error) {
	if r, err := pgx.CollectExactlyOneRow(rows, scanFullResource); err == nil {
		return r, nil
	} else {
		if err == pgx.ErrNoRows {
			err = ErrResourceNotFound
		}
		return r, err
	}

}

func scanFullResource(row pgx.CollectableRow) (Resource, error) {
	var r Resource
	err := row.Scan(
		&r.id,
		&r.name,
		&r.parentID,
		&r.dir,
		&r.created,
		&r.modified,
		&r.deleted,
		&r.permissions,
		&r.grants,
		&r.versions,
		&r.links,
		&r.visibleParent,
		&r.inheritedPermissions,
	)
	if err != nil {
		return r, err
	}
	return processResource(r)
}

func scanResourceWithoutParent(row pgx.CollectableRow) (Resource, error) {
	var r Resource
	err := row.Scan(
		&r.id,
		&r.name,
		&r.parentID,
		&r.dir,
		&r.created,
		&r.modified,
		&r.deleted,
		&r.permissions,
		&r.grants,
		&r.versions,
		&r.links,
	)
	if err != nil {
		return r, err
	}
	return processResource(r)
}

func processResource(r Resource) (Resource, error) {
	if v, err := latestVersion(r.versions); err != nil {
		return r, err
	} else {
		r.latestVersionInfo = v
	}
	return r, nil
}

func latestVersion(versionsJSON []byte) (VersionInfo, error) {
	versions := make([]VersionInfo, 0, 1)
	err := json.Unmarshal(versionsJSON, &versions)
	if err != nil {
		return VersionInfo{}, err
	}
	if len(versions) == 0 {
		return VersionInfo{
			ID:       uuid.Nil,
			Created:  0,
			Size:     0,
			MimeType: "text/plain",
			SHA256:   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
		}, nil
	}
	// TODO: add `ORDER BY` clause to queries to ensure correctness
	return versions[0], nil
}

func readPermissionFromJson(j []byte, userID int32) (Permission, error) {
	if j == nil {
		return PermissionNone, nil
	}
	p := make(map[int32]Permission)
	err := json.Unmarshal(j, &p)
	if err != nil {
		return PermissionNone, err
	}
	if p, ok := p[userID]; ok {
		return p, nil
	}
	return PermissionNone, nil
}
