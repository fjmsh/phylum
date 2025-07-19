package auth

import (
	"errors"
	"net/http"
	"net/url"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/api/v1/user"
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
		group.POST("/password/login", handlePasswordLogin)
		group.POST("/password/change", handlePasswordChange)
	}
	if auth.PasswordResetEnabled() {
		if mail.Configured() {
			passwordConfigResponse.PasswordReset = true
			group.POST("/password/request-reset", handlePasswordRequestReset)
			group.POST("/password/reset", handlePasswordReset)
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
			if e, ok := err.(*auth.PasswordRequirementsError); ok {
				panic(core.NewError(http.StatusBadRequest, "new_password_invalid", e.Error()))
			}
			return err
		} else if r, err := user.Bootstrap(c.Request.Context(), a, 0); err != nil {
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
