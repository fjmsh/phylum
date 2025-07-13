package crypt

import (
	"errors"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
)

type PasswordHasher interface {
	GenerateEncodedHash(password string) (string, error)
}

func NewPasswordHasher(cfg Config) (PasswordHasher, error) {
	if cfg.Hash == "argon2" {
		return argon2.New(cfg.Argon2), nil
	} else if cfg.Hash == "pbkdf2" {
		generator, err := pbkdf2.New(cfg.PBKDF2)
		if err != nil {
			return nil, errors.New("failed to create PBKDF2 hash generator: " + err.Error())
		}
		return generator, nil
	} else {
		return nil, errors.New("unrecognized hashing algorithm: " + cfg.Hash)
	}
}
