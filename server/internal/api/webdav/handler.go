package webdav

import (
	"errors"
	"net/http"

	webdav "codeberg.org/shroff/phylum/server/internal/api/webdav/impl"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
)

type handler struct {
	prefix     string
	lockSystem webdav.LockSystem
}

func SetupHandler(r *gin.RouterGroup) {
	handler := &handler{
		prefix:     r.BasePath(),
		lockSystem: webdav.NewMemLS(),
	}
	r.Handle("OPTIONS", "/*path", handler.HandleRequest)
	r.Handle("GET", "/*path", handler.HandleRequest)
	r.Handle("PUT", "/*path", handler.HandleRequest)
	r.Handle("HEAD", "/*path", handler.HandleRequest)
	r.Handle("POST", "/*path", handler.HandleRequest)
	r.Handle("DELETE", "/*path", handler.HandleRequest)
	r.Handle("MOVE", "/*path", handler.HandleRequest)
	r.Handle("COPY", "/*path", handler.HandleRequest)
	r.Handle("MKCOL", "/*path", handler.HandleRequest)
	r.Handle("PROPFIND", "/*path", handler.HandleRequest)
	r.Handle("PROPPATCH", "/*path", handler.HandleRequest)
	r.Handle("LOCK", "/*path", handler.HandleRequest)
	r.Handle("UNLOCK", "/*path", handler.HandleRequest)
}

func (h *handler) HandleRequest(c *gin.Context) {
	authSuccess := false
	var f *core.FileSystem
	if keyIDStr, keyStr, ok := c.Request.BasicAuth(); ok {
		ctx := c.Request.Context()
		db := db.Get(ctx)
		var a *auth.Auth
		var err error

		connectionInfo := auth.ConnectionInfoJSON(
			c.RemoteIP(),
			c.Request.Header.Get("X-Device"),
			c.Request.Header.Get("User-Agent"),
		)
		if keyIDStr == "" {
			a, err = auth.ReadAPIToken(db, keyStr, connectionInfo)
		} else {
			a, err = auth.ReadAPIKey(db, keyIDStr, keyStr, connectionInfo)
		}

		if err == nil {
			authSuccess = true
			f = a.GetFileSystem(db, pgtype.UUID{})
		} else if !errors.Is(err, auth.ErrCredentialsInvalid) {
			panic(err)
		}
	}
	if !authSuccess {
		c.Header("WWW-Authenticate", "Basic realm=\"Phylum WebDAV\"")
		c.AbortWithStatus(http.StatusUnauthorized)
		return
	}

	webdavHandler := webdav.Handler{
		Prefix:     h.prefix + "/",
		FileSystem: f,
		LockSystem: h.lockSystem,
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
