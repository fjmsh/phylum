package crypt

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
)

type Config struct {
	KDF    string        `koanf:"kdf" json:"kdf"`
	Argon2 argon2.Config `koanf:"argon2,omitempty" json:"argon2"`
	PBKDF2 pbkdf2.Config `koanf:"pbkdf2,omitempty" json:"pbkdf2"`
}
