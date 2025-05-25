package mail

import "github.com/shroff/phylum/server/internal/core/user"

func SendWelcomeEmail(u user.User) error {
	email := emails["welcome"]
	params := map[string]string{
		"name":     u.DisplayName,
		"instance": Cfg.Instance,
	}
	if u.DisplayName == "" {
		params["name"] = "there"
	}
	return send(email, u, params)
}
