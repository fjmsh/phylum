package core

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/img"
)

type Config struct {
	User                      UserConfig     `koanf:"users,omitempty"`
	Publinks                  PublinksConfig `koanf:"publinks,omitempty"`
	NoDefaultInvitePermission bool           `koanf:"no_default_invite_permission,omitempty"`
	Img                       img.Config     `koanf:"img,omitempty"`
}

type PublinksConfig struct {
	Password crypt.Config `koanf:"password,omitempty"`
}

type UserConfig struct {
	BaseDir     string          `koanf:"basedir,omitempty"`
	Permissions UserPermissions `koanf:"permissions,omitempty"`
}
