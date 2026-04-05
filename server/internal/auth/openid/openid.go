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

func GetProviderName(providerName string) (string, error) {
	if c, ok := clients[providerName]; !ok {
		return "", errors.New("OpenID provider not registered: " + providerName)
	} else {
		return c.Name, nil
	}
}

func GetClientDetails(providerName string) (string, string, error) {
	if c, ok := clients[providerName]; !ok {
		return "", "", errors.New("OpenID provider not registered: " + providerName)
	} else if config, err := getProviderConfig(c.IssuerURL); err != nil {
		return "", "", err
	} else {
		return c.ClientID, config.AuthorizationEndpoint, nil
	}
}

func GetUserInfo(providerName, authCode, redirectURI, codeVerifier string) (UserInfo, error) {
	if c, ok := clients[providerName]; !ok {
		return UserInfo{}, errors.New("OpenID provider not registered: " + providerName)
	} else if config, err := getProviderConfig(c.IssuerURL); err != nil {
		return UserInfo{}, err
	} else {
		data := url.Values{}
		data.Set("grant_type", "authorization_code")
		data.Set("code", authCode)
		data.Set("redirect_uri", redirectURI)
		data.Set("code_verifier", codeVerifier)
		if req, err := http.NewRequest("POST", config.TokenEndpoint, strings.NewReader(data.Encode())); err != nil {
			return UserInfo{}, errors.New("failed to create token request: " + err.Error())
		} else {
			credentials := base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%s", c.ClientID, c.ClientSecret)))
			req.Header.Add("Authorization", fmt.Sprintf("Basic %s", credentials))
			req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
			if res, err := http.DefaultClient.Do(req); err != nil {
				return UserInfo{}, errors.New("failed to get token response: " + err.Error())
			} else if res.StatusCode != http.StatusOK {
				return UserInfo{}, fmt.Errorf("token request failed with status %d (%s)", res.StatusCode, res.Status)
			} else {
				if accessToken, userInfo, err := parseTokenResponse(res); err != nil {
					return UserInfo{}, errors.New("failed to parse token response: " + err.Error())
				} else {
					if userInfo.Email == "" {
						if userInfo, err = fetchUserinfo(config, accessToken); err != nil {
							return userInfo, errors.New("failed to fetch user info: " + err.Error())
						}
					}
					if !userInfo.EmailVerified && !c.AllowUnverifiedEmails {
						err = errors.New("email not verified with IdP")
					}
					return userInfo, err
				}
			}
		}
	}
}

func parseTokenResponse(res *http.Response) (string, UserInfo, error) {
	var response tokenResponse
	var userInfo UserInfo
	defer res.Body.Close()
	if bodyBytes, err := io.ReadAll(res.Body); err != nil {
		return "", userInfo, errors.New("failed to read body: " + err.Error())
	} else if err = json.Unmarshal(bodyBytes, &response); err != nil {
		return "", userInfo, errors.New("failed to read id token from body: " + err.Error())
	} else if parts := strings.Split(response.IDToken, "."); len(parts) != 3 {
		return response.AccessToken, userInfo, errors.New("id token is not JWT")
	} else if jsonToken, err := base64.RawURLEncoding.DecodeString(parts[1]); err != nil {
		return response.AccessToken, userInfo, errors.New("failed to decode id token: " + err.Error())
	} else if err := json.Unmarshal(jsonToken, &userInfo); err != nil {
		return response.AccessToken, userInfo, errors.New("failed to parse id token: " + err.Error())
	} else {
		return response.AccessToken, userInfo, nil
	}
}

func fetchUserinfo(config *ProviderConfig, accessToken string) (UserInfo, error) {
	if req, err := http.NewRequest("GET", config.UserinfoEndpoint, nil); err != nil {
		return UserInfo{}, errors.New("failed to create userinfo request: " + err.Error())
	} else {
		req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", accessToken))
		if res, err := http.DefaultClient.Do(req); err != nil {
			return UserInfo{}, errors.New("failed to get userinfo response: " + err.Error())
		} else if res.StatusCode != http.StatusOK {
			return UserInfo{}, fmt.Errorf("userinfo request failed with status %d (%s)", res.StatusCode, res.Status)
		} else {
			return parseUserinfoResponse(res)
		}
	}
}

func parseUserinfoResponse(res *http.Response) (UserInfo, error) {
	var userInfo UserInfo
	defer res.Body.Close()
	if bodyBytes, err := io.ReadAll(res.Body); err != nil {
		return userInfo, errors.New("failed to read body: " + err.Error())
	} else if err = json.Unmarshal(bodyBytes, &userInfo); err != nil {
		return userInfo, errors.New("failed to read id token from body: " + err.Error())
	} else {
		return userInfo, nil
	}
}

type tokenResponse struct {
	AccessToken string `json:"access_token"`
	IDToken     string `json:"id_token"`
}

type UserInfo struct {
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name"`
	GivenName     string `json:"given_name"`
	FamilyName    string `json:"family_name"`
}
