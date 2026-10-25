package webdav

import (
	"errors"
	"io"
	"net/http"
	"strings"

	webdav "codeberg.org/shroff/phylum/server/internal/api/webdav/impl"
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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
		FileSystem: webdavCoreFS{f},
		LockSystem: h.lockSystem,
	}
	webdavHandler.ServeHTTP(c.Writer, c.Request)
}

type webdavCoreFS struct {
	f *core.FileSystem
}

func fixPath(path string) string {
	path = strings.TrimLeft(path, "/")
	if len(path) > 0 && (path[1] == '~' || path[1] == ':') {
		return path[1:]
	}
	return "/" + path
}

func (f webdavCoreFS) IsRoot(id uuid.UUID) bool {
	return f.f.IsRoot(id)
}
func (f webdavCoreFS) ResourceByPath(path string) (core.Resource, error) {
	return f.f.ResourceByPath(fixPath(path))
}
func (f webdavCoreFS) ReadDir(r core.Resource, recursive bool) ([]core.Resource, error) {
	return f.f.ReadDir(r, recursive)
}
func (f webdavCoreFS) GetVersion(r core.Resource, versionID string) (core.Version, error) {
	return f.f.GetVersion(r, versionID)
}
func (f webdavCoreFS) Walk(r core.Resource, depth int, fn func(core.Resource, string) error) error {
	return f.f.Walk(r, depth, fn)
}
func (f webdavCoreFS) GetAncestors(r core.Resource) ([]core.ResourceAncestor, error) {
	return f.f.GetAncestors(r)
}

func (f webdavCoreFS) Mkdir(path string) (err error) {
	_, err = f.f.Mkdir(fixPath(path), uuid.Nil, false, core.ResourceBindConflictResolutionError)
	return

}
func (f webdavCoreFS) CreateFileByPath(path string, in io.Reader) (err error) {
	_, err = f.f.CreateFileByPath(fixPath(path), uuid.Nil, uuid.Nil, in, core.ResourceBindConflictResolutionEnsure)
	return
}

func (f webdavCoreFS) Copy(src core.Resource, dest string, depth int, overwrite bool) (deleted bool, err error) {
	var conflictResolution core.ResourceBindConflictResolution = core.ResourceBindConflictResolutionError
	if overwrite {
		conflictResolution = core.ResourceBindConflictResolutionOverwrite
	}
	_, deleted, err = f.f.Copy(src, fixPath(dest), uuid.Nil, depth != 0, conflictResolution)
	return
}
func (f webdavCoreFS) Move(src core.Resource, dest string, overwrite bool) (deleted bool, err error) {
	var conflictResolution core.ResourceBindConflictResolution = core.ResourceBindConflictResolutionError
	if overwrite {
		conflictResolution = core.ResourceBindConflictResolutionDelete
	}
	_, deleted, err = f.f.Move(src, fixPath(dest), conflictResolution)
	return
}
func (f webdavCoreFS) Delete(r core.Resource) (err error) {
	_, err = f.f.Delete(r)
	return
}
