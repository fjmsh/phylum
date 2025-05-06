package user

import (
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

func (m manager) UpdateUserRoot(user User, root uuid.UUID) error {
	const q = "UPDATE users SET root = $2::UUID, modified = NOW() WHERE username = $1::TEXT"
	if _, err := m.db.Exec(q, user.Username, root); err != nil {
		return err
	}
	return nil
}

func (m manager) UpdateUserHome(user User, home uuid.UUID) error {
	const q = "UPDATE users SET home = $2::UUID, modified = NOW() WHERE username = $1::TEXT"
	if _, err := m.db.Exec(q, user.Username, home); err != nil {
		return err
	}
	return nil
}

func (m manager) UpdateUserDisplayName(user User, displayName string) error {
	const q = "UPDATE users SET display_name = $2::UUID, modified = NOW() WHERE username = $1::TEXT"
	if _, err := m.db.Exec(q, user.Username, displayName); err != nil {
		return err
	}
	return nil
}

func (m manager) UpdateUserPassword(user User, password string) error {
	const q = "UPDATE users SET password_hash = $2::TEXT, modified = NOW() WHERE username = $1::TEXT"
	if hash, err := crypt.GenerateArgon2EncodedHash(password); err != nil {
		return err
	} else {
		if _, err := m.db.Exec(q, user.Username, hash); err != nil {
			return err
		}
	}
	return nil
}

func (m manager) GrantUserPermissions(user User, permissions int) error {
	const q = "UPDATE users SET permissions = permissions | $2::INTEGER, modified = NOW() WHERE username = $1::UUID"
	if _, err := m.db.Exec(q, user.Username, permissions); err != nil {
		return err
	}
	return nil
}

func (m manager) RevokeUserPermissions(user User, permissions int) error {
	const q = "UPDATE users SET permissions = permissions & ~ $2::INTEGER, modified = NOW() WHERE username = $1::UUID"
	if _, err := m.db.Exec(q, user.Username, permissions); err != nil {
		return err
	}
	return nil
}
