package auth

import (
	"errors"
	"net/http"
	"net/url"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/my"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/auth/openid"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

type PasswordConfigResponse struct {
	Password        bool              `json:"password"`
	PasswordReset   bool              `json:"password_reset"`
	MagicLink       bool              `json:"magic_link"`
	OpenIDProviders []openid.Provider `json:"openid_providers"`
}

type passwordParams struct {
	Email    string `json:"email" form:"email" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

type emailParams struct {
	Email string `json:"email" form:"email" binding:"required"`
}

type tokenLoginParams struct {
	Token string `json:"token" form:"token" binding:"required"`
}

type resetPasswordParams struct {
	Email    string `json:"email" form:"email" binding:"required"`
	Token    string `json:"token" form:"token" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

var passwordConfigResponse PasswordConfigResponse

func SetupRoutes(r *gin.RouterGroup, logger *zerolog.Logger) {
	group := r.Group("/auth")
	group.GET("/config", handleConfig)

	if auth.PasswordAuthEnabled() {
		passwordConfigResponse.Password = true
		group.POST("/password/login", handlePasswordAuth)
	}
	if auth.PasswordResetEnabled() {
		if mail.Configured() {
			passwordConfigResponse.PasswordReset = true
			group.POST("/password/request-reset", handleRequestPasswordReset)
			group.POST("/password/reset", handleResetPassword)
		} else {
			logger.Warn().Msg("Password reset enabled but mail not configured")
		}
	}

	group.POST("/token/login", handleTokenLogin)
	if auth.MagicLinksEnabled() {
		if mail.Configured() {
			passwordConfigResponse.MagicLink = true
			group.POST("/token/request", handleTokenRequest)
		} else {
			logger.Warn().Msg("Magic link login enabled but mail not configured")
		}
	}

	passwordConfigResponse.OpenIDProviders = auth.OpenIDProviders()
	group.GET("/oauth/start", handleOAuthStart)
	group.GET("/oauth/redirect", handleOAuthRedirect)

	group.POST("/set-cookie", authenticator.RequireAPIKey, handleSetCookie)
}

func handleConfig(c *gin.Context) {
	c.JSON(http.StatusOK, passwordConfigResponse)
}

func handleOAuthStart(c *gin.Context) {
	provider := c.Query("provider")
	clientType := auth.OpenIDClientWeb
	if c.Query("client_type") == "native" {
		clientType = auth.OpenIDClientNative
	}
	db := db.Get(c.Request.Context())
	if authURL, err := auth.OpenIDStart(db, provider, getInstanceURL(c.Request, "/api/v1/auth/oauth/redirect"), clientType); err != nil {
		panic(err)
	} else {
		c.Redirect(http.StatusFound, authURL)
	}
}

func handleOAuthRedirect(c *gin.Context) {
	db := db.Get(c.Request.Context())

	authCode := c.Query("code")
	state := c.Query("state")

	if clientType, err := auth.OpenIDValidateAuthCode(db, state, authCode, getInstanceURL(c.Request, "/api/v1/auth/oauth/redirect")); err != nil {
		panic(err)
	} else {
		var clientURI url.URL
		if clientType == auth.OpenIDClientWeb {
			clientURI = *c.Request.URL
			clientURI.RawQuery = ""
		} else {
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
func getInstanceURL(req *http.Request, path string) string {
	uri := url.URL{
		Scheme: "https",
		Host:   req.Host,
		Path:   path,
	}

	if proto := req.Header.Get("X-Forwarded-Proto"); proto != "" {
		uri.Scheme = proto
	} else if req.TLS == nil {
		uri.Scheme = "http"
	}
	return uri.String()
}

func handleTokenLogin(c *gin.Context) {
	var params tokenLoginParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "login token not specified"))
	}

	loginAndSendResponse(c, func(db db.TxHandler) (auth.Auth, string, error) {
		return auth.PerformTokenLogin(db, params.Token)
	})
}

func handleTokenRequest(c *gin.Context) {
	var params emailParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if user, token, err := auth.CreateLoginToken(db, params.Email); err != nil {
			// Do not indicate that there was an error if no user was found
			if !errors.Is(err, core.ErrUserNotFound) {
				return err
			}
		} else {
			// TODO: #jobs #mail #error
			go func() {
				mail.SendTokenLoginEmail(user, token)
			}()
		}
		return nil
	}); err != nil {
		panic(err)
	} else {
		c.JSON(http.StatusOK, gin.H{})
	}
}

func handlePasswordAuth(c *gin.Context) {
	var params passwordParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Email or password not specified"))
	}

	loginAndSendResponse(c, func(db db.TxHandler) (auth.Auth, string, error) {
		return auth.PerformPasswordLogin(db, params.Email, params.Password)
	})
}

func handleRequestPasswordReset(c *gin.Context) {
	var params emailParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if user, token, err := auth.CreateResetToken(db, params.Email); err != nil {
			// Do not indicate that there was an error if no user was found
			if !errors.Is(err, core.ErrUserNotFound) {
				return err
			}
		} else {
			// TODO: #jobs #mail #error
			go func() {
				mail.SendPasswordResetEmail(user, token)
			}()
		}
		return nil
	}); err != nil {
		panic(err)
	} else {
		c.JSON(http.StatusOK, gin.H{})
	}
}

func handleResetPassword(c *gin.Context) {
	var params resetPasswordParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Missing Parameters"))
	}

	loginAndSendResponse(c, func(db db.TxHandler) (auth.Auth, string, error) {
		return auth.ResetUserPassword(db, params.Email, params.Token, params.Password)
	})
}

func loginAndSendResponse(c *gin.Context, loginFn func(db.TxHandler) (auth.Auth, string, error)) {
	var err error
	var key string
	var response responses.Bootstrap
	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		var a auth.Auth
		if a, key, err = loginFn(db); err != nil {
			if errors.Is(err, auth.ErrCredentialsInvalid) {
				return core.NewError(http.StatusUnauthorized, "credentials_invalid", "invalid credentials")
			}
			if errors.Is(err, auth.ErrTokenInvalid) {
				return core.NewError(http.StatusUnauthorized, "token_invalid", "token invalid")
			}
			return err
		} else if r, err := my.Bootstrap(c.Request.Context(), a, 0); err != nil {
			return err
		} else {
			response = r
			return nil
		}
	}); err != nil {
		panic(err)
	} else {
		c.JSON(http.StatusOK, responses.Login{
			APIToken:  key,
			Bootstrap: response,
		})
	}
}

func handleSetCookie(c *gin.Context) {
	token := authenticator.GetAPIKey(c)
	if token == "" {
		panic(core.NewError(http.StatusBadRequest, "missing_token", "API Key Not Specified"))
	}
	secure := c.Request.URL.Scheme == "https" || c.Request.TLS != nil
	c.SetSameSite(http.SameSiteStrictMode)
	c.SetCookie("api_token", token, 3600, "", c.Request.URL.Hostname(), secure, true)
}
