package openid

type Config struct {
	Clients []ClientConfig `koanf:"clients"`
}

type ClientConfig struct {
	ID           string `koanf:"id"`
	Name         string `koanf:"name"`
	IssuerURL    string `koanf:"issuer_url"`
	ClientID     string `koanf:"client_id"`
	ClientSecret string `koanf:"client_secret"`
}
