package auth

import (
	"crypto/rand"
	"encoding/base32"
	"encoding/base64"
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"github.com/rs/zerolog"
)

var passwordRequirements PasswordRequirements
var passwordBackend PasswordBackend
var magicLinksEnabled bool
var passwordResetEnabled bool

var adminConfig Config

const apiKeyLength = 15
const resetTokenLength = 15
const loginTokenLength = 15

const tokenValidity = 10 * time.Minute

var b64Encoder = base64.URLEncoding.WithPadding(base64.NoPadding)
var b32Encoder = base32.StdEncoding.WithPadding(base32.NoPadding)

var ErrTokenInvalid = errors.New("invalid token")
var ErrCredentialsInvalid = errors.New("invalid credentials")

func PasswordAuthEnabled() bool {
	return passwordBackend != nil
}

func PasswordBackendSupportsUpdate() bool {
	return passwordBackend != nil && passwordBackend.SupportsPasswordUpdate()
}

func PasswordResetEnabled() bool {
	return passwordResetEnabled
}

func MagicLinksEnabled() bool {
	return magicLinksEnabled
}

func OpenIDProviders() []openid.Provider {
	return openid.Providers()
}

func Configuration() Config {
	return adminConfig
}

func Initialize(cfg Config, log zerolog.Logger) error {
	passwordRequirements = cfg.Password.Requirements
	magicLinksEnabled = cfg.MagicLinks

	switch cfg.Password.Backend {
	case "crypt":
		if crypt, err := crypt.New(cfg.Password.Crypt); err != nil {
			return errors.New("failed to create crypt password backend: " + err.Error())
		} else {
			passwordBackend = crypt
		}
	case "ldap":
		if ldap, err := ldap.NewAuth(cfg.Password.LDAP, log); err != nil {
			return errors.New("failed to create ldap password backend: " + err.Error())
		} else {
			passwordBackend = ldap
		}
	case "none", "":
		// No password backend configured
	default:
		return errors.New("password backend not recognized: " + cfg.Password.Backend)
	}

	if cfg.Password.ResetEnabled {
		if passwordBackend == nil {
			log.Warn().Msg("Password reset enabled but no backend configured")
		} else if !passwordBackend.SupportsPasswordUpdate() {
			log.Warn().Msg("Password reset enabled but backend does not support update")
		} else {
			passwordResetEnabled = true
		}
	}

	methods := len(cfg.OpenID.Clients)
	if passwordBackend != nil || magicLinksEnabled {
		methods += 1
	}
	if methods < 1 {
		return errors.New("no login method configured")
	}

	if methods > 1 && !cfg.SuppressMultiProviderWarning {
		log.Warn().Msg("Using multiple login providers can lead to cross-provider impersonation " +
			"if email addresses are not guaranteed to belong to the same user across the different providers")
	}

	adminConfig = cfg
	adminConfig.Password.LDAP.Filter.BindPassword = ""
	clients := cfg.OpenID.Clients
	adminConfig.OpenID.Clients = make(map[string]openid.ClientConfig)
	for k, c := range clients {
		c.ClientSecret = ""
		adminConfig.OpenID.Clients[k] = c
	}

	return openid.Init(cfg.OpenID, log)
}

func generateSecureKey(n int) []byte {
	b := make([]byte, n)
	rand.Read(b)
	return b
}
