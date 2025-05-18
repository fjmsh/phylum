package mail

import (
	gomail "gopkg.in/mail.v2"
)

var Cfg Config
var d *gomail.Dialer

type Message struct {
	ToName   string
	ToEmail  string
	Subject  string
	Body     string
	HTMLBody string
}

func dialer() *gomail.Dialer {
	if d == nil {
		d = gomail.NewDialer(Cfg.SMTP.Host, Cfg.SMTP.Port, Cfg.SMTP.Username, Cfg.SMTP.Password)
	}
	return d
}

func Send(m Message) error {
	d := dialer()
	msg := gomail.NewMessage()
	msg.SetAddressHeader("From", Cfg.From.Email, Cfg.From.Name)
	msg.SetAddressHeader("To", m.ToEmail, m.ToName)
	msg.SetHeader("Subject", m.Subject)
	msg.SetBody("text/plain", m.Body)
	if m.HTMLBody != "" {
		msg.AddAlternative("text/html", m.HTMLBody)
	}
	return d.DialAndSend(msg)
}
