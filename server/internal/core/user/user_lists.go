package user

import (
	"time"

	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func (m manager) GetSharedResources(u User) (result []fs.Resource, err error) {
	// TODO: This doesn't take permissions into account. is this okay?
	res, err := m.db.Queries.SharedResources(m.ctx, db.SharedResourcesParams{Username: u.Username, UserHome: u.Home})
	if err != nil {
		return
	}

	result = make([]fs.Resource, len(res))
	for i, r := range res {
		var deleted *time.Time
		if r.Deleted.Valid {
			deleted = &r.Deleted.Time
		}
		result[i] = fs.Resource{
			ID:            r.ID,
			ParentID:      r.Parent,
			Name:          r.Name,
			Dir:           r.Dir,
			Created:       r.Created.Time,
			Modified:      r.Modified.Time,
			Deleted:       deleted,
			ContentSize:   r.ContentSize,
			ContentType:   r.ContentType,
			ContentSHA256: r.ContentSha256,
			Permissions:   string(r.Permissions),
			// Not Needed
			// Path:                 "",
			// UserPermissions:      0,
			// InheritedPermissions: "",
		}
	}
	return
}
