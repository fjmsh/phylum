package mail

import "github.com/shroff/phylum/server/internal/core/user"

type ResetPasswordParams struct {
	Name string
	URL  string
}

func SendPasswordResetEmail(u user.User, token string) error {
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
