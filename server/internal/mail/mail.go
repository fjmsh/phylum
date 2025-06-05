package mail

import (
	"io"

	"github.com/shroff/phylum/server/internal/core"
	"github.com/sirupsen/logrus"
	gomail "gopkg.in/mail.v2"
)

var Cfg Config
var d *gomail.Dialer

type Recipient struct {
	Name  string
	Email string
}

func dialer() *gomail.Dialer {
	if d == nil {
		d = gomail.NewDialer(Cfg.SMTP.Host, Cfg.SMTP.Port, Cfg.SMTP.Username, Cfg.SMTP.Password)
	}
	return d
}

func send(e Email, rcpt core.User, params any) error {
	d := dialer()
	msg := gomail.NewMessage()
	msg.SetAddressHeader("From", Cfg.From.Email, Cfg.From.Name)
	msg.SetAddressHeader("To", rcpt.Email, rcpt.Name)
	msg.SetHeader("Subject", e.Subject)
	msg.SetBodyWriter("text/plain", func(w io.Writer) error {
		return e.Plain.Execute(w, params)
	})
	msg.AddAlternativeWriter("text/html", func(w io.Writer) error {
		return e.HTML.Execute(w, params)
	})
	err := d.DialAndSend(msg)
	if err != nil {
		logrus.Warn(err)
	}
	return err
}
