package openid

import (
	"fmt"

	"github.com/rs/zerolog"
)

var clients = make(map[string]ProviderConfig)

type Provider struct {
	ID                    string `json:"id"`
	Name                  string `json:"name"`
	ClientID              string `json:"client_id"`
	AuthorizationEndpoint string `json:"endpoint"`
}

var log zerolog.Logger

func Init(cfg []ProviderConfig, l zerolog.Logger) error {
	log = l.With().Str("c", "auth.openid").Logger()
	for _, c := range cfg {
		clients[c.ID] = c
		if _, err := getOpenIDConfiguration(c.IssuerURL); err != nil {
			log.Warn().Err(err).Str("id", c.ID).Str("issuer_url", c.IssuerURL).Msg("Unable to get OpenID config")
			return fmt.Errorf("failed to get openid configuration for %q at %q: %w", c.ID, c.IssuerURL, err)
		}

	}
	return nil
}

func Providers() []Provider {
	p := make([]Provider, 0, len(clients))
	for _, c := range clients {
		endpoint := ""
		if config, err := getOpenIDConfiguration(c.IssuerURL); err != nil {
			log.Warn().Err(err).Str("id", c.ID).Str("issuer_url", c.IssuerURL).Msg("Unable to get OpenID config")
		} else {
			endpoint = config.AuthorizationEndpoint
		}
		p = append(p, Provider{
			ID:                    c.ID,
			Name:                  c.Name,
			ClientID:              c.ClientID,
			AuthorizationEndpoint: endpoint,
		})
	}
	return p
}
