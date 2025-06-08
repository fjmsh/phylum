package mail

import "codeberg.org/shroff/phylum/server/internal/core"

type ResetPasswordParams struct {
	Name string
	URL  string
}

func SendPasswordResetEmail(u core.User, token string) error {
	email := emails["password_reset"]
	params := map[string]string{
		"name":     u.Name,
		"email":    u.Email,
		"instance": Cfg.Instance,
		"token":    token,
	}
	if u.Name == "" {
		params["name"] = "there"
	}
	return send(email, u, params)
}
