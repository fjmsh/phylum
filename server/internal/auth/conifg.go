package auth

import "codeberg.org/shroff/phylum/server/internal/auth/crypt"

type Config struct {
	Password PasswordConfig `koanf:"password"`
}

type PasswordConfig struct {
	Backend      string               `koanf:"backend"`
	Crypt        crypt.Config         `koanf:"crypt"`
	Requirements PasswordRequirements `koanf:"requirements"`
}

type PasswordRequirements struct {
	Length  int `koanf:"length"`
	Lower   int `koanf:"lower"`
	Upper   int `koanf:"upper"`
	Numeric int `koanf:"numeric"`
	Symbols int `koanf:"symbols"`
}
