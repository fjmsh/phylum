package auth

import (
	"crypto/rand"
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
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/rs/zerolog"
)

var autoCreate []*regexp.Regexp
var passwordConfig PasswordConfig
var passwordBackend PasswordBackend

const apiKeyLength = 32
const resetTokenLength = 24
const resetTokenDuration = 10 * time.Minute

var apiKeyValidity = pgtype.Interval{
	Days:  30,
	Valid: true,
}

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

func Init(cfg Config, log zerolog.Logger) error {
	passwordConfig = cfg.Password

	if cfg.Password.Backend == "crypt" {
		passwordBackend = &crypt.Auth{}
	} else if cfg.Password.Backend == "ldap" {
		if a, err := ldap.NewAuth(cfg.Password.LDAP, log); err != nil {
			return err
		} else {
			passwordBackend = a
		}
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

func generateRandomString(n int) string {
	b := make([]byte, n*3/4)
	rand.Read(b)
	return base64.URLEncoding.EncodeToString(b)
}
