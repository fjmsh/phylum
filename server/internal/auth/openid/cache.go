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

type cachedConfiguration struct {
	expires       time.Time
	lastModified  string
	configuration *OpenIDConfiguration
}

type OpenIDConfiguration struct {
	AuthorizationEndpoint string `json:"authorization_endpoint"`
}

var mu = &sync.RWMutex{}
var cache = make(map[string]cachedConfiguration)

func getOpenIDConfiguration(issuerURL string) (*OpenIDConfiguration, error) {
	if cached := getCached(issuerURL); cached != nil {
		return cached, nil
	}

	var config OpenIDConfiguration
	if url, err := url.JoinPath(issuerURL, ".well-known/openid-configuration"); err != nil {
		return nil, err
	} else if response, err := http.DefaultClient.Get(url); err != nil {
		return nil, err
	} else {
		if response.StatusCode == http.StatusNotModified {
			return renewCached(issuerURL, response)
		} else {
			defer response.Body.Close()
			if body, err := io.ReadAll(response.Body); err != nil {
				return nil, err
			} else if err := json.Unmarshal(body, &config); err != nil {
				return nil, err
			} else {
				putCached(issuerURL, &config, response)
				return &config, nil
			}
		}
	}
}

func getCached(issuerURL string) *OpenIDConfiguration {
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

func putCached(issuerURL string, config *OpenIDConfiguration, response *http.Response) {
	mu.Lock()
	defer mu.Unlock()

	reasons, expires, err := cachecontrol.CachableResponse(nil, response, cachecontrol.Options{})
	if err == nil && reasons == nil {
		lastModified := ""
		lastModifiedHeader := response.Header["Last-Modified"]
		if lastModifiedHeader != nil {
			lastModified = lastModifiedHeader[0]
		}
		cache[issuerURL] = cachedConfiguration{
			expires:       expires,
			lastModified:  lastModified,
			configuration: config,
		}
	}
}

func renewCached(issuerURL string, response *http.Response) (*OpenIDConfiguration, error) {
	mu.Lock()
	defer mu.Unlock()

	c, ok := cache[issuerURL]
	if !ok {
		return nil, errors.New("trying to refresh issuer that is not in cache")
	}

	if reasons, expires, err := cachecontrol.CachableResponse(nil, response, cachecontrol.Options{}); err != nil {
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
