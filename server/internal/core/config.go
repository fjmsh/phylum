package core

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/img"
)

type Config struct {
	User     UserConfig     `koanf:"users"`
	Publinks PublinksConfig `koanf:"publinks"`
	Img      img.Config     `koanf:"img"`
}

type PublinksConfig struct {
	Password crypt.Config `koanf:"password"`
}

type UserConfig struct {
	BaseDir    string          `koanf:"basedir"`
	Permisison UserPermissions `koanf:"permission"`
}
