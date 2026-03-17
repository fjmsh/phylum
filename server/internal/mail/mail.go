package mail

import (
	"errors"
	"io"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/rs/zerolog"
	gomail "gopkg.in/mail.v2"
)

var initialized = false
var dialer *gomail.Dialer

var instance string
var from FromConfig
var logger zerolog.Logger

var ErrEmailNotConfigured = errors.New("email not configured")

func Initialize(cfg Config, l zerolog.Logger) error {
	if initialized {
		return errors.New("already initialized")
	}
	initialized = true
	logger = l.With().Str("mod", "email").Logger()
	if cfg.SMTP.Host == "" {
		return ErrEmailNotConfigured
	}

	dialer = gomail.NewDialer(cfg.SMTP.Host, cfg.SMTP.Port, cfg.SMTP.Username, cfg.SMTP.Password)
	from = cfg.From
	instance = cfg.Instance

	return nil
}

func Configured() bool {
	return dialer != nil
}

func SendTestEmail(email string) error {
	return send(emails["test"], core.User{Email: email}, nil)
}

func SendWelcomeEmail(u core.User) error {
	return send(emails["welcome"], u, nil)
}

func SendPasswordResetEmail(u core.User, token string) error {
	return send(emails["password_reset"], u, map[string]any{
		"token": token,
	})
}

func SendTokenLoginEmail(u core.User, token string) error {
	return send(emails["token_login"], u, map[string]any{
		"token": token,
	})
}

func SendResourceShareEmail(u core.User, r core.Resource) error {
	return send(emails["resource_share"], u, map[string]any{
		"resource_name": r.Name(),
		"resource_id":   r.ID().String(),
		"resource_dir":  r.Dir(),
	})
}

func send(e Email, rcpt core.User, params map[string]any) error {
	if dialer == nil {
		return ErrEmailNotConfigured
	}
	if params == nil {
		params = make(map[string]any)
	}
	params["name"] = rcpt.Name
	params["email"] = rcpt.Email
	params["instance"] = instance
	if rcpt.Name == "" {
		params["name"] = "there"
	}

	msg := gomail.NewMessage()
	msg.SetAddressHeader("From", from.Email, from.Name)
	msg.SetAddressHeader("To", rcpt.Email, rcpt.Name)

	sb := strings.Builder{}
	e.Subject.Execute(&sb, params)
	msg.SetHeader("Subject", sb.String())

	msg.SetBodyWriter("text/plain", func(w io.Writer) error {
		return e.Plain.ExecuteTemplate(w, "base", params)
	})
	msg.AddAlternativeWriter("text/html", func(w io.Writer) error {
		return e.HTML.ExecuteTemplate(w, "base", params)
	})
	err := dialer.DialAndSend(msg)
	if err != nil {
		logger.Warn().Err(err).Msg("failed to send email")
	}
	return err
}
