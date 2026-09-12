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

type Handler struct {
	passwordRequirements PasswordRequirements
	passwordBackend      PasswordBackend
	magicLinksEnabled    bool
	passwordResetEnabled bool
	openIDHandler        openid.Handler
}

var handler *Handler

const apiKeyLength = 15
const resetTokenLength = 15
const loginTokenLength = 15

const tokenValidity = 10 * time.Minute

var b64Encoder = base64.URLEncoding.WithPadding(base64.NoPadding)
var b32Encoder = base32.StdEncoding.WithPadding(base32.NoPadding)

var ErrTokenInvalid = errors.New("invalid token")
var ErrCredentialsInvalid = errors.New("invalid credentials")

func (h *Handler) PasswordAuthEnabled() bool {
	return h.passwordBackend != nil
}

func (h *Handler) PasswordBackendSupportsUpdate() bool {
	return h.passwordBackend != nil && h.passwordBackend.SupportsPasswordUpdate()
}

func (h *Handler) PasswordResetEnabled() bool {
	return h.passwordResetEnabled
}

func (h *Handler) MagicLinksEnabled() bool {
	return h.magicLinksEnabled
}

func (h *Handler) OpenIDHandler() openid.Handler {
	return h.openIDHandler
}

func (h *Handler) OpenIDProviders() []openid.Provider {
	return h.OpenIDHandler().Providers()
}

func Initialize(cfg Config, log zerolog.Logger) error {
	if h, err := CreateHandler(cfg, log); err != nil {
		return err
	} else {
		handler = h
		return nil
	}
}

func Get() *Handler {
	return handler
}

func CreateHandler(cfg Config, log zerolog.Logger) (*Handler, error) {
	h := &Handler{}
	h.passwordRequirements = cfg.Password.Requirements
	h.magicLinksEnabled = cfg.MagicLinks

	switch cfg.Password.Backend {
	case "crypt":
		if crypt, err := crypt.New(cfg.Password.Crypt); err != nil {
			return nil, errors.New("failed to create crypt password backend: " + err.Error())
		} else {
			h.passwordBackend = crypt
		}
	case "ldap":
		if ldap, err := ldap.NewAuth(cfg.Password.LDAP, log); err != nil {
			return nil, errors.New("failed to create ldap password backend: " + err.Error())
		} else if _, err := ldap.VerifyUserPassword(nil, "email@example.com", "password"); err != nil {
			return nil, errors.New("failed to connect to ldap backend: " + err.Error())
		} else {
			h.passwordBackend = ldap
		}
	case "none", "":
		// No password backend configured
	default:
		return nil, errors.New("password backend not recognized: " + cfg.Password.Backend)
	}

	if cfg.Password.ResetEnabled {
		if h.passwordBackend == nil {
			log.Warn().Msg("Password reset enabled but no backend configured")
		} else if !h.passwordBackend.SupportsPasswordUpdate() {
			log.Warn().Msg("Password reset enabled but backend does not support update")
		} else {
			h.passwordResetEnabled = true
		}
	}

	methods := len(cfg.OpenID.Clients)
	if h.passwordBackend != nil || h.magicLinksEnabled {
		methods += 1
	}
	if methods < 1 {
		return nil, errors.New("No login method configured")
	}

	if methods > 1 && !cfg.SuppressMultiProviderWarning {
		log.Warn().Msg("Using multiple login providers can lead to cross-provider impersonation " +
			"if email addresses are not guaranteed to belong to the same user across the different providers")
	}

	h.openIDHandler = openid.CreateHandler(cfg.OpenID, log)
	return h, nil
}

func generateSecureKey(n int) []byte {
	b := make([]byte, n)
	rand.Read(b)
	return b
}
