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
	ancestors            uuid.UUIDs
	apiKeyScope          ResourcePermission
	userPermissions      ResourcePermission
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

func (f *FileSystem) collectFullResource(rows pgx.Rows) (Resource, error) {
	if r, err := pgx.CollectExactlyOneRow(rows, f.scanFullResource); err == nil {
		return r, nil
	} else {
		if err == pgx.ErrNoRows {
			err = ErrResourceNotFound
		}
		return r, err
	}

}

func (f *FileSystem) scanFullResource(row pgx.CollectableRow) (Resource, error) {
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
		&r.inheritedPermissions,
		&r.ancestors,
	)
	if err != nil {
		return r, err
	}
	if r, err = populateLatestVersion(r); err != nil {
		return r, err
	}
	r.apiKeyScope = f.getApiKeyScopePermissions(r.id, r.ancestors)
	r.userPermissions, err = f.getUserPermission(r.permissions)
	if err != nil {
		return r, err
	}

	if parentPermission, err := f.getUserPermission(r.inheritedPermissions); err != nil {
		return r, err
	} else if len(r.ancestors) > 0 {
		var parentAncestors uuid.UUIDs
		if len(r.ancestors) > 1 {
			parentAncestors = r.ancestors[1:]
		}
		scopePermissions := f.getApiKeyScopePermissions(r.ancestors[0], parentAncestors)
		if scopePermissions&parentPermission&ResourcePermissionRead == ResourcePermissionRead {
			r.visibleParent = r.parentID
		}
	}

	return r, err
}

func collectSimpleResource(rows pgx.Rows) (Resource, error) {
	if r, err := pgx.CollectExactlyOneRow(rows, scanSimpleResource); err == nil {
		return r, nil
	} else {
		if err == pgx.ErrNoRows {
			err = ErrResourceNotFound
		}
		return r, err
	}

}

func scanSimpleResourceParentVisible(row pgx.CollectableRow) (r Resource, err error) {
	if r, err = scanSimpleResource(row); err == nil {
		r.visibleParent = r.parentID
	}
	return
}

func scanSimpleResource(row pgx.CollectableRow) (Resource, error) {
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
	return populateLatestVersion(r)
}

func populateLatestVersion(r Resource) (Resource, error) {
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
	return versions[0], nil
}
