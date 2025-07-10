package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base32"
	"encoding/base64"
	"errors"
	"net/http"
	"regexp"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/rs/zerolog"
)

var autoCreate []*regexp.Regexp
var passwordRequirements PasswordRequirements
var passwordBackend PasswordBackend

const apiKeyLength = 15
const resetTokenLength = 15
const loginTokenLength = 15

const tokenValidity = 10 * time.Minute

var ErrCredentialsInvalid = core.NewError(http.StatusUnauthorized, "credentials_invalid", "invalid credentials")

func SupportsPasswordAuth() bool {
	return passwordBackend != nil
}

func SupportsPasswordReset() bool {
	return passwordBackend != nil && passwordBackend.SupportsPasswordUpdate()
}

func OpenIDProviders() []openid.Provider {
	return openid.Providers()
}

func Initialize(cfg Config, log zerolog.Logger) error {
	passwordRequirements = cfg.Password.Requirements

	if cfg.Password.Backend == "crypt" {
		crypt.Cfg = cfg.Password.Crypt
		passwordBackend = &crypt.Auth{}
	} else if cfg.Password.Backend == "ldap" {
		if a, err := ldap.NewAuth(cfg.Password.LDAP, log); err != nil {
			return err
		} else {
			passwordBackend = a
		}
	} else if cfg.Password.Backend == "none" {
		passwordBackend = nil
	} else if cfg.Password.Backend != "" {
		return errors.New("password backend not recognized: " + cfg.Password.Backend)
	}

	autoCreate = make([]*regexp.Regexp, len(cfg.AutoCreate))
	for i, w := range cfg.AutoCreate {
		autoCreate[i] = regexp.MustCompile(strings.ReplaceAll(strings.ToLower(w), "*", ".*"))
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

// generateSecureKey generates a base32 (standard) encoded string with n bytes
// of entropy from a cryptographically secure random source. Ideally, n should
// be a multiple of 5
func generateSecureKey(n int) string {
	b := make([]byte, n)
	rand.Read(b)
	return base32.StdEncoding.EncodeToString(b)
}

func generatePKCEChallenge() (string, string) {
	verifierLen := 64
	numBytes := verifierLen * 3 / 4
	b := make([]byte, numBytes)
	rand.Read(b)
	codeVerifier := base64.RawURLEncoding.EncodeToString(b)
	if len(codeVerifier) > 128 {
		codeVerifier = codeVerifier[:128]
	}

	hash := sha256.Sum256([]byte(codeVerifier))
	codeChallenge := base64.RawURLEncoding.EncodeToString(hash[:])
	return codeVerifier, codeChallenge
}
