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

type Mailer struct {
	dialer   *gomail.Dialer
	instance string
	from     FromConfig
	logger   zerolog.Logger
}

var ErrEmailNotConfigured = errors.New("email not configured")
var m Mailer

func SetDefaultMailer(mailer Mailer) {
	m = mailer
}

func CreateMailer(cfg Config, l zerolog.Logger) (Mailer, error) {
	var mailer Mailer
	mailer.logger = l.With().Str("mod", "email").Logger()
	if cfg.SMTP.Host == "" {
		return Mailer{}, ErrEmailNotConfigured
	}

	mailer.dialer = gomail.NewDialer(cfg.SMTP.Host, cfg.SMTP.Port, cfg.SMTP.Username, cfg.SMTP.Password)
	mailer.from = cfg.From
	mailer.instance = cfg.Instance

	return mailer, nil
}

func Configured() bool {
	return m.dialer != nil
}

func (m Mailer) SendTestEmail(email string) error {
	return m.send(emails["test"], core.User{Email: email}, nil)
}

func SendWelcomeEmail(u core.User) error {
	return m.send(emails["welcome"], u, nil)
}

func SendPasswordResetEmail(u core.User, token string) error {
	return m.send(emails["password_reset"], u, map[string]any{
		"token": token,
	})
}

func SendTokenLoginEmail(u core.User, token string) error {
	return m.send(emails["token_login"], u, map[string]any{
		"token": token,
	})
}

func SendResourceShareEmail(u core.User, r core.Resource) error {
	return m.send(emails["resource_share"], u, map[string]any{
		"resource_name": r.Name(),
		"resource_id":   r.ID().String(),
		"resource_dir":  r.Dir(),
	})
}

func (m Mailer) send(e Email, rcpt core.User, params map[string]any) error {
	if m.dialer == nil {
		return ErrEmailNotConfigured
	}
	if params == nil {
		params = make(map[string]any)
	}
	params["name"] = rcpt.Name
	params["email"] = rcpt.Email
	params["instance"] = m.instance
	if rcpt.Name == "" {
		params["name"] = "there"
	}

	msg := gomail.NewMessage()
	msg.SetAddressHeader("From", m.from.Email, m.from.Name)
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
	err := m.dialer.DialAndSend(msg)
	if err != nil {
		m.logger.Warn().Err(err).Msg("failed to send email")
	}
	return err
}
