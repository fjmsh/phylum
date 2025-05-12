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
	contentLength        int
	contentType          string
	contentSHA256        string
	permissions          []byte
	grants               []byte
	links                []byte
	inheritedPermissions []byte
	visibleParent        pgtype.UUID
	userPermission       Permission
}

func (r Resource) ID() uuid.UUID                { return r.id }
func (r Resource) Name() string                 { return r.name }
func (r Resource) Dir() bool                    { return r.dir }
func (r Resource) Created() time.Time           { return r.created }
func (r Resource) Modified() time.Time          { return r.modified }
func (r Resource) Deleted() pgtype.Timestamp    { return r.deleted }
func (r Resource) ContentLength() int           { return r.contentLength }
func (r Resource) ContentSHA256() string        { return r.contentSHA256 }
func (r Resource) ContentType() string          { return r.contentType }
func (r Resource) Grants() []byte               { return r.grants }
func (r Resource) Links() []byte                { return r.links }
func (r Resource) VisibleParentID() pgtype.UUID { return r.visibleParent }
func (r Resource) InheritedPermissions() []byte { return r.inheritedPermissions }

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
		&r.contentLength,
		&r.contentType,
		&r.contentSHA256,
		&r.permissions,
		&r.grants,
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
	} else if p, err := readPermissionFromJson(r.permissions, f.username); err != nil {
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
		&r.contentLength,
		&r.contentType,
		&r.contentSHA256,
		&r.permissions,
		&r.grants,
		&r.links,
	)
	if err != nil {
		return r, err
	}
	permission := Permission(0)
	if f.fullAccess {
		permission = -1
	} else if p, err := readPermissionFromJson(r.permissions, f.username); err != nil {
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

func readPermissionFromJson(j []byte, username string) (Permission, error) {
	if j == nil {
		return PermissionNone, nil
	}
	p := make(map[string]Permission)
	err := json.Unmarshal(j, &p)
	if err != nil {
		return PermissionNone, err
	}
	if p, ok := p[username]; ok {
		return p, nil
	}
	return PermissionNone, nil
}
