package core

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/preview"
)

type Config struct {
	User     UserConfig     `koanf:"users"`
	Publinks PublinksConfig `koanf:"publinks"`
	Preview  preview.Config `koanf:"preview"`
}

type PublinksConfig struct {
	Password crypt.Config `koanf:"password"`
}

type UserConfig struct {
	BaseDir    string          `koanf:"basedir"`
	Permisison UserPermissions `koanf:"permission"`
}
