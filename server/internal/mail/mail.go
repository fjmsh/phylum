package mail

import (
	"errors"
	"io"

	"codeberg.org/shroff/phylum/server/internal/core"
	gomail "gopkg.in/mail.v2"
)

var initialized = false
var dialer *gomail.Dialer

var instance string
var from FromConfig

var EmailNotConfigured = errors.New("email not configured")

func Initialize(cfg Config) error {
	if initialized {
		return errors.New("already initialized")
	}
	initialized = true
	if cfg.SMTP.Host == "" {
		return EmailNotConfigured
	}

	dialer = gomail.NewDialer(cfg.SMTP.Host, cfg.SMTP.Port, cfg.SMTP.Username, cfg.SMTP.Password)
	from = cfg.From
	instance = cfg.Instance

	return nil
}

func SendWelcomeEmail(u core.User) error {
	return send(emails["welcome"], u, nil)
}

func SendPasswordResetEmail(u core.User, token string) error {
	return send(emails["password_reset"], u, map[string]string{
		"token": token,
	})
}

func send(e Email, rcpt core.User, params map[string]string) error {
	if dialer == nil {
		return EmailNotConfigured
	}
	if params == nil {
		params = make(map[string]string)
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
	msg.SetHeader("Subject", e.Subject)
	msg.SetBodyWriter("text/plain", func(w io.Writer) error {
		return e.Plain.ExecuteTemplate(w, "base", params)
	})
	msg.AddAlternativeWriter("text/html", func(w io.Writer) error {
		return e.HTML.ExecuteTemplate(w, "base", params)
	})
	err := dialer.DialAndSend(msg)
	return err
}
