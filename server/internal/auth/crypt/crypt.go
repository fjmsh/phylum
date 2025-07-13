package crypt

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

type Auth interface {
	SupportsPasswordUpdate() bool
	UpdateUserPassword(db db.Handler, email, password string) error
	VerifyUserPassword(db db.Handler, email, password string) (bool, error)
}

type auth struct {
	cfg       Config
	generator interface {
		GenerateEncodedHash(password string) (string, error)
	}
}

func New(cfg Config) (Auth, error) {
	var generator interface {
		GenerateEncodedHash(password string) (string, error)
	}
	if cfg.Hash == "argon2" {
		generator = argon2.New(cfg.Argon2)
	} else {
		return nil, errors.New("unrecognized hashing algorithm: " + cfg.Hash)
	}

	return &auth{
		cfg:       cfg,
		generator: generator,
	}, nil
}

func (a *auth) SupportsPasswordUpdate() bool {
	return true
}

func (a *auth) UpdateUserPassword(db db.Handler, email, password string) error {
	const q = "UPDATE users SET password_hash = $2::TEXT, modified = NOW() WHERE email = $1::TEXT"
	if hash, err := a.generator.GenerateEncodedHash(password); err != nil {
		return err
	} else {
		if _, err := db.Exec(q, email, hash); err != nil {
			return err
		}
	}
	return nil
}

func (a *auth) VerifyUserPassword(db db.Handler, email, password string) (bool, error) {
	const q = "SELECT password_hash FROM users WHERE email = $1::TEXT"
	row := db.QueryRow(q, strings.ToLower(email))
	var encodedHash string
	if err := row.Scan(&encodedHash); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, err
	}

	return VerifyPasswordHash(password, encodedHash)
}

func VerifyPasswordHash(password, encodedHash string) (bool, error) {
	parts := strings.Split(encodedHash, "$")
	parts = parts[1:]

	if strings.HasPrefix(parts[0], "argon2") {
		return argon2.VerifyEncodedHash(password, parts)
	}
	index := strings.Index(encodedHash[1:], "$")
	if index < 0 {
	}
	return false, errors.New("unrecognized encoded hash algorithm: " + parts[0])
}
