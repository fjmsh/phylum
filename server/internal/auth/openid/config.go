package openid

type Config struct {
	Clients map[string]ClientConfig `koanf:"clients"`
}

type ClientConfig struct {
	Name                  string `koanf:"name"`
	IssuerURL             string `koanf:"issuer_url"`
	ClientID              string `koanf:"client_id"`
	ClientSecret          string `koanf:"client_secret"`
	AllowUnverifiedEmails bool   `koanf:"allow_unverified_emails"`
}
