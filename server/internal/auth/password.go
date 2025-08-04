package auth

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
)

type PasswordBackend interface {
	SupportsPasswordUpdate() bool
	VerifyUserPassword(db db.Handler, email, password string) (bool, error)
	UpdateUserPassword(db db.Handler, email, password string) error
}

func VerifyUserPassword(d db.Handler, email, password string) (*Auth, error) {
	email = strings.ToLower(email)
	if b, err := passwordBackend.VerifyUserPassword(d, email, password); err != nil {
		return nil, err
	} else if !b {
		return nil, ErrCredentialsInvalid
	}
	user, err := core.UserByEmail(d, email)
	if errors.Is(err, core.ErrUserNotFound) && shouldAutoCreate(email) {
		err = d.RunInTx(func(db db.TxHandler) error {
			user, err = core.CreateUser(db, email, "", false)
			return err
		})
	}
	return NewSUAuth(user), err
}

func PerformPasswordLogin(db db.TxHandler, email, password string) (auth *Auth, apiToken string, err error) {
	if auth, err = VerifyUserPassword(db, email, password); err != nil {
		return
	} else {
		_, _, apiToken, err = GenerateAPIKey(db, auth, "Password Login")
		return
	}
}
