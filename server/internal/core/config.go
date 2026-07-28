package core

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/img"
)

type Config struct {
	User     UserConfig `koanf:"users"`
	Publinks struct {
		Password crypt.Config `koanf:"password"`
	} `koanf:"publinks"`
	NoDefaultInvitePermission bool       `koanf:"no_default_invite_permission"`
	Img                       img.Config `koanf:"img"`
}

type UserConfig struct {
	BaseDir     string          `koanf:"basedir"`
	Permissions UserPermissions `koanf:"permissions"`
}
