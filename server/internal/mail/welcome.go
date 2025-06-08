package mail

import "codeberg.org/shroff/phylum/server/internal/core"

func SendWelcomeEmail(u core.User) error {
	email := emails["welcome"]
	params := map[string]string{
		"name":     u.Name,
		"instance": Cfg.Instance,
	}
	if u.Name == "" {
		params["name"] = "there"
	}
	return send(email, u, params)
}
