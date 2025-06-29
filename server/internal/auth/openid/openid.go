package openid

import (
	"bytes"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/rs/zerolog"
)

var clients = make(map[string]ClientConfig)

type Provider struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

var log zerolog.Logger

func Init(cfg Config, l zerolog.Logger) error {
	log = l.With().Str("c", "auth.openid").Logger()
	for _, c := range cfg.Clients {
		clients[c.ID] = c
		if _, err := getProviderConfig(c.IssuerURL); err != nil {
			log.Warn().Err(err).Str("id", c.ID).Str("issuer_url", c.IssuerURL).Msg("Unable to get OpenID config")
			return fmt.Errorf("failed to get openid configuration for %q at %q: %w", c.ID, c.IssuerURL, err)
		}

	}
	return nil
}

func Providers() []Provider {
	p := make([]Provider, 0, len(clients))
	for _, c := range clients {
		p = append(p, Provider{
			ID:   c.ID,
			Name: c.Name,
		})
	}
	return p
}

func GetProviderDetails(providerName string) (string, string, error) {
	if c, ok := clients[providerName]; !ok {
		return "", "", errors.New("OpenID provider not registered: " + providerName)
	} else if config, err := getProviderConfig(c.IssuerURL); err != nil {
		return "", "", err
	} else {
		return c.ClientID, config.AuthorizationEndpoint, nil
	}
}

func GetIDToken(providerName, authCode, redirectURI string) (idToken IDToken, err error) {
	if c, ok := clients[providerName]; !ok {
		return idToken, errors.New("OpenID provider not registered: " + providerName)
	} else if config, err := getProviderConfig(c.IssuerURL); err != nil {
		return idToken, err
	} else {
		body := map[string]string{
			"client_id":     c.ClientID,
			"client_secret": c.ClientSecret,
			"grant_type":    "authorization_code",
			"code":          authCode,
			"redirect_uri":  redirectURI,
		}
		bodyBytes, _ := json.Marshal(body)
		if req, err := http.NewRequest("POST", config.TokenEndpoint, bytes.NewBuffer(bodyBytes)); err != nil {
			return idToken, errors.New("failed to create token request: " + err.Error())
		} else if res, err := http.DefaultClient.Do(req); err != nil {
			return idToken, errors.New("failed to get token response: " + err.Error())
		} else {
			return extractIDToken(res)
		}
	}
}

func extractIDToken(res *http.Response) (idToken IDToken, err error) {
	if res.StatusCode != http.StatusOK {
	}
	var response tokenResponse
	defer res.Body.Close()
	if bodyBytes, err := io.ReadAll(res.Body); err != nil {
		return idToken, errors.New("failed to read body: " + err.Error())
	} else if err = json.Unmarshal(bodyBytes, &response); err != nil {
		return idToken, errors.New("failed to read id token from body: " + err.Error())
	} else if parts := strings.Split(response.IDToken, "."); len(parts) != 3 {
		return idToken, errors.New("id token is not JWT")
	} else if jsonToken, err := base64.RawURLEncoding.DecodeString(parts[1]); err != nil {
		return idToken, errors.New("failed to decode id token: " + err.Error())
	} else if err := json.Unmarshal(jsonToken, &idToken); err != nil {
		return idToken, errors.New("failed to parse id token: " + err.Error())
	} else {
		return idToken, nil
	}
}

type tokenResponse struct {
	IDToken string `json:"id_token"`
}

type IDToken struct {
	Email    string `json:"email"`
	FullName string `json:"full_name"`
}

func generateRandomString(n int) string {
	b := make([]byte, n*3/4)
	rand.Read(b)
	return base64.URLEncoding.EncodeToString(b)
}
