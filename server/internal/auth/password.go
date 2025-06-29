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

func VerifyUserPassword(d db.Handler, email, password string) (core.User, error) {
	if b, err := passwordBackend.VerifyUserPassword(d, email, password); err != nil {
		return core.User{}, err
	} else if !b {
		return core.User{}, ErrCredentialsInvalid
	}
	user, err := core.UserByEmail(d, email)
	if errors.Is(err, core.ErrUserNotFound) {
		for _, domain := range autoCreateDomains {
			if strings.HasSuffix(strings.ToLower(email), "@"+strings.ToLower(domain)) {
				err = d.RunInTx(func(db db.TxHandler) error {
					user, err = core.CreateUser(db, email, "", false)
					return err
				})
			}
		}
	}
	return user, err
}

func PerformPasswordLogin(db db.TxHandler, email, password string) (core.User, string, error) {
	if user, err := VerifyUserPassword(db, email, password); err != nil {
		return core.User{}, "", err
	} else if token, err := insertAPIKey(db, user.ID); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, nil
	}
}
