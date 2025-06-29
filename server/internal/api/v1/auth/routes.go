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
)

type PasswordConfigResponse struct {
	Password        bool              `json:"password"`
	PasswordReset   bool              `json:"password_reset"`
	OpenIDProviders []openid.Provider `json:"openid_providers"`
}

type passwordParams struct {
	Email    string `json:"email" form:"email" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

type requestPasswordResetParams struct {
	Email string `json:"email" form:"email" binding:"required"`
}

type resetPasswordParams struct {
	Email    string `json:"email" form:"email" binding:"required"`
	Token    string `json:"token" form:"token" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

func SetupRoutes(r *gin.RouterGroup) {
	group := r.Group("/auth")
	group.GET("/config", handleConfig)
	group.POST("/password", handlePasswordAuth)
	group.POST("/request-password-reset", handleRequestPasswordReset)
	group.POST("/reset-password", handleResetPassword)
	group.GET("/oauth/start", handleOAuthStart)
	group.GET("/oauth/redirect", handleOAuthRedirect)
	group.POST("/oauth/login", handleOAuthLogin)
	group.POST("/set-cookie", authenticator.RequireToken, handleSetCookie)
}

func handleConfig(c *gin.Context) {
	response := PasswordConfigResponse{
		Password:        auth.SupportsPasswordAuth(),
		PasswordReset:   auth.SupportsPasswordReset(),
		OpenIDProviders: auth.OpenIDProviders(),
	}
	c.JSON(http.StatusOK, response)
}

func handleOAuthStart(c *gin.Context) {
	provider := c.Query("provider")
	clientType := auth.OpenIDClientWeb
	if c.Query("client_type") == "native" {
		clientType = auth.OpenIDClientNative
	}
	db := db.Get(c.Request.Context())
	if authURL, err := auth.OpenIDStart(db, provider, getRedirectURL(c.Request), clientType); err != nil {
		panic(err)
	} else {
		c.Redirect(http.StatusFound, authURL)
	}
}

func handleOAuthRedirect(c *gin.Context) {
	db := db.Get(c.Request.Context())

	authCode := c.Query("code")
	sessionID := c.Query("state")

	if clientType, err := auth.OpenIDValidateAuthCode(db, sessionID, authCode, getRedirectURL(c.Request)); err != nil {
		panic(err)
	} else {
		var clientURI url.URL
		if clientType == auth.OpenIDClientWeb {
			clientURI = *c.Request.URL
			clientURI.RawQuery = ""
		} else {
			clientURI = url.URL{Scheme: "drive.phylum.cloud"}
		}
		clientURI.Path = "/login/oauth"
		c.Redirect(http.StatusFound, clientURI.String())
	}
}
func getRedirectURL(req *http.Request) string {
	uri := url.URL{
		Scheme: "https",
		Host:   req.Host,
		Path:   "/api/v1/auth/oauth/redirect",
	}

	if proto := req.Header.Get("X-Forwarded-Proto"); proto != "" {
		uri.Scheme = proto
	} else if req.TLS == nil {
		uri.Scheme = "http"
	}
	return uri.String()
}

func handleOAuthLogin(c *gin.Context) {

}

func handlePasswordAuth(c *gin.Context) {
	var params passwordParams
	err := c.ShouldBind(&params)
	if err != nil {
		panic(core.NewError(http.StatusBadRequest, "missing_params", "Email or password not specified"))
	}

	var token string
	var response responses.Bootstrap
	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if user, t, err := auth.PerformPasswordLogin(db, params.Email, params.Password); err != nil {
			return err
		} else if r, err := my.Bootstrap(c.Request.Context(), user, 0); err != nil {
			return err
		} else {
			token = t
			response = r
			return nil
		}
	}); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.Login{
			AccessToken: token,
			Bootstrap:   response,
		})

	}
}

func handleRequestPasswordReset(c *gin.Context) {
	var params requestPasswordResetParams
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
			// TODO: #jobs #mail
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

	var token string
	var response responses.Bootstrap
	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if user, t, err := auth.ResetUserPassword(db, params.Email, params.Token, params.Password); err != nil {
			return err
		} else if r, err := my.Bootstrap(c.Request.Context(), user, 0); err != nil {
			return err
		} else {
			token = t
			response = r
			return nil
		}
	}); err != nil {
		panic(err)
	} else {
		c.JSON(200, responses.Login{
			AccessToken: token,
			Bootstrap:   response,
		})

	}
}

func handleSetCookie(c *gin.Context) {
	token := authenticator.GetToken(c)
	if token == "" {
		panic(core.NewError(http.StatusBadRequest, "missing_token", "Auth Token Not Specified"))
	}
	secure := c.Request.URL.Scheme == "https"
	c.SetSameSite(http.SameSiteStrictMode)
	c.SetCookie("auth_token", token, 3600, "", c.Request.URL.Hostname(), secure, true)
}
