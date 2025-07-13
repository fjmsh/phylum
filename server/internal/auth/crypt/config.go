package crypt

import "codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"

type Config struct {
	Hash   string        `koanf:"hash"`
	Argon2 argon2.Config `koanf:"argon2"`
}
