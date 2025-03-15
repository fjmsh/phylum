package fs

import (
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) ResourceByPath(path string) (Resource, error) {
	return f.resourceFromResult(f.db.ResourceByPath(f.ctx, db.ResourceByPathParams{Root: &f.rootID, Path: path}))
}

func (f filesystem) ResourceByID(id uuid.UUID) (Resource, error) {
	return f.resourceFromResult(f.db.ResourceByID(f.ctx, id))
}

func (f filesystem) resourceFromResult(e []db.FullResource, err error) (Resource, error) {
	if len(e) == 0 {
		err = ErrResourceNotFound
	}
	if err != nil {
		return Resource{}, err
	}
	var b strings.Builder
	found := false
	permission := Permission(0)
	ancestry := make([]ResourceInfo, 0, len(e)-1)
	var info ResourceInfo
	for i := len(e) - 1; i >= 0; i-- {
		if !found {
			if e[i].ID == f.rootID {
				found = true
				e[i].Parent = nil
			}
		}
		if found {
			if len(ancestry) != 1 {
				b.WriteByte('/')
			}
			if len(ancestry) != 0 {
				b.WriteString(e[i].Name)
			}
			info = resourceInfoFromDBPublinkedResource(e[i])
			if i != 0 {
				ancestry = append(ancestry, info)
			}

			if f.fullAccess {
				permission = -1
			} else {
				if p, err := readPermissionFromJson(e[i].Permissions, f.username); err != nil {
					return Resource{}, err
				} else {
					permission = permission | p
				}
			}
		}
	}
	if !found || permission&PermissionRead == 0 {
		return Resource{}, ErrResourceNotFound
	}
	return Resource{
		f:              f,
		Ancestors:      ancestry,
		Info:           info,
		userPermission: permission,
	}, nil
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

func resourceInfoFromDBPublinkedResource(r db.FullResource) ResourceInfo {
	var delTime *time.Time
	if r.Deleted.Valid {
		delTime = &r.Deleted.Time
	}
	return ResourceInfo{
		id:            r.ID,
		parentID:      r.Parent,
		name:          r.Name,
		dir:           r.Dir,
		created:       r.Created.Time,
		modified:      r.Modified.Time,
		deleted:       delTime,
		contentLength: r.ContentLength,
		contentType:   r.ContentType,
		contentSHA256: r.ContentSha256,
		permissions:   r.Permissions,
		publinks:      r.Publinks,
	}
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
