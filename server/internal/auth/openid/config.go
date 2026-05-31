package openid

type Config struct {
	Clients map[string]ClientConfig `koanf:"clients,omitempty" json:"clients"`
}

type ClientConfig struct {
	Name                  string `koanf:"name" json:"name"`
	IssuerURL             string `koanf:"issuer_url" json:"issuer_url"`
	ClientID              string `koanf:"client_id" json:"client_id"`
	ClientSecret          string `koanf:"client_secret" json:"client_secret"`
	AllowUnverifiedEmails bool   `koanf:"allow_unverified_emails" json:"allow_unverified_emails"`
	AutoCreateUsers       bool   `koanf:"auto_create_users" json:"auto_create_users"`
}
