package auth

import (
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/auth/openid"
)

type Config struct {
	SuppressMultiProviderWarning bool           `koanf:"suppress_multi_provider_warning,omitempty" json:"-"`
	Password                     PasswordConfig `koanf:"password" json:"password"`
	MagicLinks                   bool           `koanf:"magic_links,omitempty" json:"magic_links"`
	OpenID                       openid.Config  `koanf:"openid,omitempty" json:"openid"`
}

type PasswordConfig struct {
	Backend      string               `koanf:"backend" json:"backend"`
	ResetEnabled bool                 `koanf:"reset_enabled" json:"reset_enabled"`
	Crypt        crypt.Config         `koanf:"crypt,omitempty" json:"crypt"`
	LDAP         ldap.Config          `koanf:"ldap,omitempty" json:"ldap"`
	Requirements PasswordRequirements `koanf:"requirements,omitempty" json:"requirements"`
}

type PasswordRequirements struct {
	Length  int `koanf:"length,omitempty" json:"length"`
	Lower   int `koanf:"lower,omitempty" json:"lower"`
	Upper   int `koanf:"upper,omitempty" json:"upper"`
	Numeric int `koanf:"numeric,omitempty" json:"numeric"`
	Symbols int `koanf:"symbols,omitempty" json:"symbols"`
}
