package openid

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
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
	log = l.With().Str("mod", "auth.openid").Logger()
	for _, c := range cfg.Clients {
		clients[c.ID] = c
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
		data := url.Values{}
		data.Set("grant_type", "authorization_code")
		data.Set("code", authCode)
		data.Set("redirect_uri", redirectURI)
		if req, err := http.NewRequest("POST", config.TokenEndpoint, strings.NewReader(data.Encode())); err != nil {
			return idToken, errors.New("failed to create token request: " + err.Error())
		} else {
			credentials := base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%s", c.ClientID, c.ClientSecret)))
			req.Header.Add("Authorization", fmt.Sprintf("Basic %s", credentials))
			req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
			if res, err := http.DefaultClient.Do(req); err != nil {
				return idToken, errors.New("failed to get token response: " + err.Error())
			} else if res.StatusCode != http.StatusOK {
				return idToken, fmt.Errorf("id token request failed with status %d (%s)", res.StatusCode, res.Status)
			} else {
				return extractIDToken(res)
			}
		}
	}
}

func extractIDToken(res *http.Response) (idToken IDToken, err error) {
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
		fmt.Println(string(jsonToken))
		return idToken, nil
	}
}

type tokenResponse struct {
	IDToken string `json:"id_token"`
}

type IDToken struct {
	Email      string `json:"email"`
	Name       string `json:"name"`
	GivenName  string `json:"given_name"`
	FamilyName string `json:"family_name"`
}
