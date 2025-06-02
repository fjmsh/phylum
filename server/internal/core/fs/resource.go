package fs

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type Resource struct {
	f                    filesystem
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
	userPermission       Permission
}

type Version struct {
	ID       uuid.UUID `json:"id"`
	Created  int       `json:"created"`
	Size     int64     `json:"size"`
	MimeType string    `json:"mime_type"`
	SHA256   string    `json:"sha256"`
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

func (r Resource) LatestVersion() (Version, error) {
	versions := make([]Version, 0, 1)
	err := json.Unmarshal(r.versions, &versions)
	if err != nil {
		return Version{}, err
	}
	if len(versions) == 0 {
		return Version{
			ID:       uuid.Nil,
			Created:  int(r.created.Unix()),
			Size:     0,
			MimeType: "text/plain",
			SHA256:   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
		}, nil
	}
	version := Version{}
	for _, v := range versions {
		if v.Created > version.Created {
			version = v
		}
	}
	return version, nil
}

func (r Resource) hasPermission(p Permission) bool {
	return r.userPermission&p != 0
}

func (f filesystem) collectFullResource(rows pgx.Rows) (Resource, error) {
	if r, err := pgx.CollectExactlyOneRow(rows, f.scanFullResource); err == nil {
		return r, nil
	} else {
		if err == pgx.ErrNoRows {
			err = ErrResourceNotFound
		}
		return r, err
	}

}

func (f filesystem) scanFullResource(row pgx.CollectableRow) (Resource, error) {
	r := Resource{f: f}
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
	permission := Permission(0)
	if f.fullAccess {
		permission = -1
	} else if p, err := readPermissionFromJson(r.permissions, f.userID); err != nil {
		return Resource{}, err
	} else {
		permission = p
	}
	if permission&PermissionRead == 0 {
		return Resource{}, ErrResourceNotFound
	}
	r.userPermission = permission
	return r, err
}

func (f filesystem) scanResourceWithoutParent(row pgx.CollectableRow) (Resource, error) {
	r := Resource{f: f}
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
	permission := Permission(0)
	if f.fullAccess {
		permission = -1
	} else if p, err := readPermissionFromJson(r.permissions, f.userID); err != nil {
		return Resource{}, err
	} else {
		permission = p
	}
	if permission&PermissionRead == 0 {
		return Resource{}, ErrResourceNotFound
	}
	r.userPermission = permission
	return r, err
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
