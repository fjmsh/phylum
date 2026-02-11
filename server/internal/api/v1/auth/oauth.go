package auth

import (
	"fmt"
	"net/http"
	"net/url"
	"strconv"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
)

func handleOAuthStart(c *gin.Context) {
	provider := c.Query("provider")
	clientType := auth.OpenIDClientWeb
	loopbackPort := 0
	if c.Query("client_type") == "native" {
		clientType = auth.OpenIDClientNative
	}
	if c.Query("client_type") == "loopback" {
		clientType = auth.OpenIDClientLoopback
		if port, err := strconv.Atoi(c.Query("loopback_port")); err != nil {
			panic(err)
		} else {
			loopbackPort = port
		}
	}
	db := db.Get(c.Request.Context())
	if authURL, err := auth.OpenIDStart(db, provider, getInstanceURL(c.Request, "/api/v1/auth/oauth/redirect"), clientType, loopbackPort); err != nil {
		panic(err)
	} else {
		c.Redirect(http.StatusFound, authURL)
	}
}

func handleOAuthRedirect(c *gin.Context) {
	db := db.Get(c.Request.Context())

	authCode := c.Query("code")
	state := c.Query("state")

	if clientType, loopbackPort, err := auth.OpenIDValidateAuthCode(db, state, authCode, getInstanceURL(c.Request, "/api/v1/auth/oauth/redirect")); err != nil {
		panic(err)
	} else {
		var clientURI url.URL
		switch clientType {
		case auth.OpenIDClientWeb:
			clientURI = *c.Request.URL
			clientURI.RawQuery = ""
		case auth.OpenIDClientLoopback:
			clientURI = url.URL{Scheme: "http", Host: fmt.Sprintf("localhost:%d", loopbackPort)}
		case auth.OpenIDClientNative:
			clientURI = url.URL{Scheme: "cloud.phylum.drive"}
		}
		clientURI.Path = "/login/token"
		q := url.Values{}
		q.Add("token", state)
		q.Add("instance", getInstanceURL(c.Request, ""))
		clientURI.RawQuery = q.Encode()
		c.Redirect(http.StatusFound, clientURI.String())
	}
}
