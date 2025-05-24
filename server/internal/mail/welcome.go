package mail

type WelcomeParams struct {
	Name string
	URL  string
}

func SendWelcomeEmail(rcpt Recipient, params WelcomeParams) error {
	email := emails["welcome"]
	if params.Name == "" {
		params.Name = "there"
	}
	params.URL = Cfg.URL
	return send(email, rcpt, params)
}
