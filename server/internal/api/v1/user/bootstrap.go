package user

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/api/v1/users"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
)

var bootstrapConfig map[string]any

func InitBootstrapConfig(publinkPath string) {
	bootstrapConfig = gin.H{
		"version":         config.Version,
		"publink_path":    publinkPath,
		"password_update": auth.Get().PasswordBackendSupportsUpdate(),
		"mail":            mail.Enabled(),
		"allow_invites":   core.AllowInvites(),
	}
}

func handleBootstrapRoute(c *gin.Context) {
	var since int64
	if s := c.Request.URL.Query().Get("since"); s != "" {
		var err error
		since, err = strconv.ParseInt(s, 10, 64)
		if err != nil {
			panic(core.NewError(http.StatusBadRequest, "invalid_parameters", "Invalid Parameters"))
		}
	}

	if response, err := Bootstrap(c.Request.Context(), authenticator.GetAuth(c), since); err != nil {
		panic(err)
	} else {
		c.JSON(200, response)
	}
}

func Bootstrap(ctx context.Context, auth *auth.Auth, since int64) (responses.Bootstrap, error) {
	if !auth.HasScope("bookmarks:list") || !auth.HasScope("users:list") || !auth.HasScope("profile:read") {
		return responses.Bootstrap{}, core.ErrInsufficientScope
	}
	if bookmarks, err := ListBookmarks(ctx, auth.UserID(), since); err != nil {
		return responses.Bootstrap{}, err
	} else if users, err := users.ListUsers(ctx, since); err != nil {
		return responses.Bootstrap{}, err
	} else if u, err := core.UserByID(db.Get(ctx), auth.UserID()); err != nil {
		return responses.Bootstrap{}, err
	} else {
		return responses.Bootstrap{
			User: responses.LoggedInUser{
				User: responses.User{
					ID:    u.ID,
					Email: u.Email,
					Name:  u.Name,
				},
				Home:        u.Home,
				Permissions: u.Permissions,
			},
			Bookmarks: bookmarks,
			Users:     users,
			Until:     int(time.Now().UnixMilli()) - 100,
			Config:    bootstrapConfig,
			Clear:     since == 0,
		}, nil
	}

}
