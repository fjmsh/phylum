package fs

import (
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	path = strings.Trim(path, "/")
	segments := strings.Split(path, "/")
	if path == "" {
		// Calling strings.Split on an empty string returns a slice of length 1. That breaks the query
		segments = []string{}
	}

	res, err := f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: f.rootID, Search: segments})
	if err == pgx.ErrNoRows {
		err = ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}
	return f.ResourceByID(res.ID)
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	r, err := f.db.ResourceByID(f.ctx, db.ResourceByIDParams{Root: f.rootID, ResourceID: id, Username: f.username})
	// TODO: verify found
	if err == pgx.ErrNoRows || !r.Found || (r.UserPermission&PermissionRead == 0) {
		err = ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}

	var delTime *time.Time
	if r.Deleted.Valid {
		delTime = &r.Deleted.Time
	}
	return Resource{
		ID:            r.ID,
		ParentID:      r.Parent,
		Name:          r.Name,
		Dir:           r.Dir,
		Created:       r.Created.Time,
		Modified:      r.Modified.Time,
		Deleted:       delTime,
		ContentSize:   r.ContentSize,
		ContentType:   r.ContentType,
		ContentSHA256: r.ContentSha256,
		Permissions:   string(r.Permissions),
		// Definitely Needed
		Path:                 r.Path,
		UserPermissions:      r.UserPermission,
		InheritedPermissions: string(r.InheritedPermissions),
	}, nil
}

func (f filesystem) ResourceByPathOrUUID(pathOrUUID string) (Resource, error) {
	if pathOrUUID == "" {
		return Resource{}, ErrResourcePathInvalid
	}
	if pathOrUUID[0] == '/' {
		return f.ResourceByPath(pathOrUUID)
	}
	if id, err := uuid.Parse(pathOrUUID); err != nil {
		return Resource{}, err
	} else {
		return f.ResourceByID(id)
	}
}
