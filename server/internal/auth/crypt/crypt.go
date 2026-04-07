package crypt

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

type Crypt struct {
	generator PasswordHasher
}

func New(cfg Config) (*Crypt, error) {
	var generator PasswordHasher
	if cfg.KDF == "argon2" {
		generator = argon2.New(cfg.Argon2)
	} else if cfg.KDF == "pbkdf2" {
		var err error
		generator, err = pbkdf2.New(cfg.PBKDF2)
		if err != nil {
			return nil, errors.New("failed to create PBKDF2 hash generator: " + err.Error())
		}
	} else {
		return nil, errors.New("unrecognized hashing algorithm: " + cfg.KDF)
	}

	return &Crypt{
		generator: generator,
	}, nil
}

func (a *Crypt) SupportsPasswordUpdate() bool {
	return true
}

func (a *Crypt) UpdateUserPassword(db db.Handler, email, password string) error {
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

func (a *Crypt) VerifyUserPassword(db db.Handler, email, password string) (bool, error) {
	const q = "SELECT password_hash FROM users WHERE email = $1::TEXT"
	row := db.QueryRow(q, strings.ToLower(email))
	var encodedHash string
	if err := row.Scan(&encodedHash); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, err
	}
	if encodedHash == "" {
		return false, nil
	}

	return VerifyPasswordHash(password, encodedHash)
}

func (a *Crypt) AutoCreateUsers() bool {
	return false
}

func VerifyPasswordHash(password, encodedHash string) (bool, error) {
	parts := strings.Split(encodedHash, "$")
	parts = parts[1:]

	if strings.HasPrefix(parts[0], "argon2") {
		return argon2.VerifyEncodedHash(password, parts)
	}
	if strings.HasPrefix(parts[0], "pbkdf2") {
		return pbkdf2.VerifyEncodedHash(password, parts)
	}
	return false, errors.New("unrecognized encoded hash algorithm: " + parts[0])
}
