package crypt

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

var Cfg Config

type Auth struct {
}

func (a *Auth) SupportsPasswordUpdate() bool {
	return true
}

func (a *Auth) UpdateUserPassword(db db.Handler, email, password string) error {
	const q = "UPDATE users SET password_hash = $2::TEXT, modified = NOW() WHERE email = $1::TEXT"
	if hash, err := Generate(password); err != nil {
		return err
	} else {
		if _, err := db.Exec(q, email, hash); err != nil {
			return err
		}
	}
	return nil
}

func (a *Auth) VerifyUserPassword(db db.Handler, email, password string) (bool, error) {
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

	if parts[0] == "argon2id" {
		return verifyArgon2(password, parts[1:])
	}
	index := strings.Index(encodedHash[1:], "$")
	if index < 0 {
	}
	return false, errors.New("unrecognized encoded hash algorithm: " + parts[0])
}

func Generate(password string) (string, error) {
	if Cfg.Hash == "argon2" {
		return generateArgon2(password)
	}
	return "", errors.New("unrecognized hash algorithm: " + Cfg.Hash)
}
