package fs

import (
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/api/serve"
)

type Resource struct {
	f              filesystem
	id             uuid.UUID
	parentID       *uuid.UUID
	name           string
	dir            bool
	created        time.Time
	modified       time.Time
	deleted        *time.Time
	contentLength  int64
	contentType    string
	contentSHA256  string
	permissions    []byte
	grants         []byte
	userPermission Permission
}

func (r Resource) ID() uuid.UUID         { return r.id }
func (r Resource) ParentID() *uuid.UUID  { return r.parentID }
func (r Resource) Name() string          { return r.name }
func (r Resource) Dir() bool             { return r.dir }
func (r Resource) Created() time.Time    { return r.created }
func (r Resource) Modified() time.Time   { return r.modified }
func (r Resource) Deleted() *time.Time   { return r.deleted }
func (r Resource) ContentLength() int64  { return r.contentLength }
func (r Resource) ContentSHA256() string { return r.contentSHA256 }
func (r Resource) ContentType() string   { return r.contentType }
func (r Resource) Permissions() []byte   { return r.permissions }
func (r Resource) Grants() []byte        { return r.grants }

func (r Resource) hasPermission(p Permission) bool {
	return r.userPermission&p != 0
}

func (f filesystem) collectResource(rows pgx.Rows) (Resource, error) {
	if r, err := pgx.CollectExactlyOneRow(rows, f.scanResource); err == nil {
		return r, nil
	} else {
		if err == pgx.ErrNoRows {
			err = ErrResourceNotFound
		}
		return r, err
	}

}

func (f filesystem) scanServeResource(row pgx.CollectableRow) (serve.Resource, error) {
	return f.scanResource(row)
}

func (f filesystem) scanResource(row pgx.CollectableRow) (Resource, error) {
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
