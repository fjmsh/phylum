package openid

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"sync"
	"time"

	"github.com/pquerna/cachecontrol"
)

type cachedProviderConfig struct {
	expires       time.Time
	lastModified  string
	configuration *ProviderConfig
}

type ProviderConfig struct {
	AuthorizationEndpoint string `json:"authorization_endpoint"`
	TokenEndpoint         string `json:"token_endpoint"`
}

var mu = &sync.RWMutex{}
var cache = make(map[string]cachedProviderConfig)

func getProviderConfig(issuerURL string) (*ProviderConfig, error) {
	if cached := getCached(issuerURL); cached != nil {
		return cached, nil
	}

	var config ProviderConfig
	if url, err := url.JoinPath(issuerURL, ".well-known/openid-configuration"); err != nil {
		return nil, err
	} else if req, err := http.NewRequest("GET", url, nil); err != nil {
		return nil, err
	} else if res, err := http.DefaultClient.Do(req); err != nil {
		return nil, err
	} else {
		if res.StatusCode == http.StatusNotModified {
			return renewCached(issuerURL, req, res)
		} else {
			defer res.Body.Close()
			if body, err := io.ReadAll(res.Body); err != nil {
				return nil, err
			} else if err := json.Unmarshal(body, &config); err != nil {
				return nil, err
			} else {
				putCached(issuerURL, &config, req, res)
				return &config, nil
			}
		}
	}
}

func getCached(issuerURL string) *ProviderConfig {
	mu.RLock()
	c, ok := cache[issuerURL]
	mu.RUnlock()
	if !ok {
		return nil
	}

	if c.expires.After(time.Now()) {
		return c.configuration
	} else {
		mu.Lock()
		delete(cache, issuerURL)
		mu.Unlock()
		return nil
	}
}

func putCached(issuerURL string, config *ProviderConfig, req *http.Request, res *http.Response) {
	mu.Lock()
	defer mu.Unlock()

	reasons, expires, err := cachecontrol.CachableResponse(req, res, cachecontrol.Options{})
	if err == nil && reasons == nil {
		lastModified := ""
		lastModifiedHeader := res.Header["Last-Modified"]
		if lastModifiedHeader != nil {
			lastModified = lastModifiedHeader[0]
		}
		cache[issuerURL] = cachedProviderConfig{
			expires:       expires,
			lastModified:  lastModified,
			configuration: config,
		}
	}
}

func renewCached(issuerURL string, req *http.Request, res *http.Response) (*ProviderConfig, error) {
	mu.Lock()
	defer mu.Unlock()

	c, ok := cache[issuerURL]
	if !ok {
		return nil, errors.New("trying to refresh issuer that is not in cache")
	}

	if reasons, expires, err := cachecontrol.CachableResponse(req, res, cachecontrol.Options{}); err != nil {
		delete(cache, issuerURL)
		return nil, err
	} else if reasons != nil {
		delete(cache, issuerURL)
		return nil, errors.New("response should not be cached: " + reasons[0].String())
	} else {
		c.expires = expires
		cache[issuerURL] = c
		return c.configuration, nil
	}
}
