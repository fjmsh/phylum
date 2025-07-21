package auth

import (
	"crypto/rand"
	"encoding/base32"
	"encoding/base64"
	"errors"
	"regexp"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"github.com/rs/zerolog"
)

var autoCreate []*regexp.Regexp
var passwordRequirements PasswordRequirements
var passwordBackend PasswordBackend
var magicLinksEnabled bool
var passwordResetEnabled bool

const apiKeyLength = 15
const resetTokenLength = 15
const loginTokenLength = 15

const tokenValidity = 10 * time.Minute

var b64Encoder = base64.StdEncoding.WithPadding(base64.NoPadding)
var b32Encoder = base32.StdEncoding.WithPadding(base32.NoPadding)

var ErrTokenInvalid = errors.New("invalid token")
var ErrCredentialsInvalid = errors.New("invalid credentials")

func PasswordAuthEnabled() bool {
	return passwordBackend != nil
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

func Initialize(cfg Config, log zerolog.Logger) error {
	passwordRequirements = cfg.Password.Requirements
	magicLinksEnabled = cfg.MagicLinks

	if cfg.Password.Backend == "crypt" {
		if crypt, err := crypt.New(cfg.Password.Crypt); err != nil {
			return errors.New("failed to create crypt password backend: " + err.Error())
		} else {
			passwordBackend = crypt
		}
	} else if cfg.Password.Backend == "ldap" {
		if ldap, err := ldap.NewAuth(cfg.Password.LDAP, log); err != nil {
			return errors.New("failed to create ldap password backend: " + err.Error())
		} else {
			passwordBackend = ldap
		}
	} else if cfg.Password.Backend == "none" {
	} else if cfg.Password.Backend != "" {
		return errors.New("password backend not recognized: " + cfg.Password.Backend)
	}

	autoCreate = make([]*regexp.Regexp, len(cfg.AutoCreate))
	for i, w := range cfg.AutoCreate {
		autoCreate[i] = regexp.MustCompile(strings.ReplaceAll(strings.ToLower(w), "*", ".*"))
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

	return openid.Init(cfg.OpenID, log)
}

func shouldAutoCreate(email string) bool {
	for _, p := range autoCreate {
		if p.MatchString(email) {
			return true
		}
	}
	return false
}

func generateSecureKey(n int) []byte {
	b := make([]byte, n)
	rand.Read(b)
	return b
}
