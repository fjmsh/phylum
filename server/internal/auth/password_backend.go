package auth

import (
	"codeberg.org/shroff/phylum/server/internal/db"
)

type PasswordBackend interface {
	SupportsPasswordUpdate() bool
	VerifyUserPassword(db db.Handler, email, password string) (bool, error)
	UpdateUserPassword(db db.Handler, email, password string) error
}
