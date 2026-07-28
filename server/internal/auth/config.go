package auth

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/auth/openid"
)

type Config struct {
	SuppressMultiProviderWarning bool           `koanf:"suppress_multi_provider_warning" json:"-"`
	Password                     PasswordConfig `koanf:"password" json:"password"`
	MagicLinks                   bool           `koanf:"magic_links" json:"magic_links"`
	OpenID                       openid.Config  `koanf:"openid" json:"openid"`
}

type PasswordConfig struct {
	Backend      string               `koanf:"backend" json:"backend"`
	ResetEnabled bool                 `koanf:"reset_enabled" json:"reset_enabled"`
	Crypt        crypt.Config         `koanf:"crypt" json:"crypt"`
	LDAP         ldap.Config          `koanf:"ldap" json:"ldap"`
	Requirements PasswordRequirements `koanf:"requirements" json:"requirements"`
}

type PasswordRequirements struct {
	Length  int `koanf:"length" json:"length"`
	Lower   int `koanf:"lower" json:"lower"`
	Upper   int `koanf:"upper" json:"upper"`
	Numeric int `koanf:"numeric" json:"numeric"`
	Symbols int `koanf:"symbols" json:"symbols"`
}
