package webdav

import (
	"errors"
	"net/http"

	webdav "codeberg.org/shroff/phylum/server/internal/api/webdav/impl"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/sirupsen/logrus"
)

type handler struct {
	prefix     string
	lockSystem webdav.LockSystem
}

func SetupHandler(r *gin.RouterGroup) {
	logrus.Debug("Setting up WebDAV access at " + r.BasePath())
	handler := &handler{
		prefix:     r.BasePath(),
		lockSystem: webdav.NewMemLS(),
	}
	r.Handle("OPTIONS", "/:root/*path", handler.HandleRequest)
	r.Handle("GET", "/:root/*path", handler.HandleRequest)
	r.Handle("PUT", "/:root/*path", handler.HandleRequest)
	r.Handle("HEAD", "/:root/*path", handler.HandleRequest)
	r.Handle("POST", "/:root/*path", handler.HandleRequest)
	r.Handle("DELETE", "/:root/*path", handler.HandleRequest)
	r.Handle("MOVE", "/:root/*path", handler.HandleRequest)
	r.Handle("COPY", "/:root/*path", handler.HandleRequest)
	r.Handle("MKCOL", "/:root/*path", handler.HandleRequest)
	r.Handle("PROPFIND", "/:root/*path", handler.HandleRequest)
	r.Handle("PROPPATCH", "/:root/*path", handler.HandleRequest)
	r.Handle("LOCK", "/:root/*path", handler.HandleRequest)
	r.Handle("UNLOCK", "/:root/*path", handler.HandleRequest)
}

func (h *handler) HandleRequest(c *gin.Context) {
	authSuccess := false
	var f core.FileSystem
	if email, pass, ok := c.Request.BasicAuth(); ok {
		ctx := c.Request.Context()
		if u, err := auth.VerifyUserPassword(ctx, email, pass); err == nil {
			authSuccess = true
			root := c.Param("root")
			f = u.OpenFileSystem(ctx)
			if root[0] == '~' {
				id, err := core.UserHome(db.Get(c.Request.Context()), root[1:])
				if err != nil {
					if errors.Is(err, core.ErrUserNotFound) {
						c.AbortWithStatus(http.StatusNotFound)
						return
					} else {
						panic(err)
					}
				}
				f = f.WithPathRoot(id)
			} else if id, err := uuid.Parse(root); err != nil {
				f = f.WithPathRoot(pgtype.UUID{Bytes: id, Valid: false})
			} else {
				c.AbortWithStatus(http.StatusNotFound)
				return
			}
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
		Prefix:     h.prefix + "/" + c.Param("root"),
		FileSystem: f,
		LockSystem: h.lockSystem,
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}
