package user

import (
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (m manager) UpdateUserRoot(user User, root uuid.UUID) error {
	return m.db.UpdateUserRoot(m.ctx, db.UpdateUserRootParams{Username: user.Username, Root: root})
}

func (m manager) UpdateUserHome(user User, home uuid.UUID) error {
	return m.db.UpdateUserHome(m.ctx, db.UpdateUserHomeParams{Username: user.Username, Home: home})
}

func (m manager) UpdateUserDisplayName(user User, displayName string) error {
	return m.db.UpdateUserDisplayName(m.ctx, db.UpdateUserDisplayNameParams{Username: user.Username, DisplayName: displayName})
}

func (m manager) GrantUserPermissions(user User, permissions int32) error {
	return m.db.GrantUserPermissions(m.ctx, db.GrantUserPermissionsParams{Username: user.Username, Permissions: permissions})
}

func (m manager) RevokeUserPermissions(user User, permissions int32) error {
	return m.db.RevokeUserPermissions(m.ctx, db.RevokeUserPermissionsParams{Username: user.Username, Permissions: ^permissions})
}
