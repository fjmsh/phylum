package mail

import "github.com/shroff/phylum/server/internal/core/user"

type ResetPasswordParams struct {
	Name string
	URL  string
}

func SendPasswordResetEmail(u user.User, token string) error {
	email := emails["password_reset"]
	params := map[string]string{
		"name":     u.DisplayName,
		"email":    u.Email,
		"base_url": Cfg.URL,
		"token":    token,
	}
	return send(email, u, params)
}
