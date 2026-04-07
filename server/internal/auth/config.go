package auth

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/auth/openid"
)

type Config struct {
	SuppressMultiProviderWarning bool           `koanf:"suppress_multi_provider_warning"`
	Password                     PasswordConfig `koanf:"password"`
	MagicLinks                   bool           `koanf:"magic_links"`
	OpenID                       openid.Config  `koanf:"openid"`
}

type PasswordConfig struct {
	Backend      string               `koanf:"backend"`
	ResetEnabled bool                 `koanf:"reset_enabled"`
	Crypt        crypt.Config         `koanf:"crypt"`
	LDAP         ldap.Config          `koanf:"ldap"`
	Requirements PasswordRequirements `koanf:"requirements"`
}

type PasswordRequirements struct {
	Length  int `koanf:"length"`
	Lower   int `koanf:"lower"`
	Upper   int `koanf:"upper"`
	Numeric int `koanf:"numeric"`
	Symbols int `koanf:"symbols"`
}
