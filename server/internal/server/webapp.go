package server

import (
	"embed"
	"mime"
	"net/http"
	"path"
	"regexp"
	"strings"

	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
)

//go:embed __static/**
var staticFS embed.FS

var immutableResources = []*regexp.Regexp{
	regexp.MustCompile(`^/main.dart.[0-9abcdef]{8}.((js)|(mjs)|(wasm))$`),
	regexp.MustCompile(`^/sqlite3.[0-9abcdef]{8}.wasm$`),
	regexp.MustCompile(`^/((flutter_bootstrap)|(phylum_app_worker)|(drift_worker)|).[0-9abcdef]{8}.js$`),
	regexp.MustCompile(`^/phylum.[0-9abcdef]{8}.webmanifest$`),
}

func (s *server) setupWebApp() {
	fs := static.LocalFile(s.cfg.WebAppSrc, false)
	fileserver := http.FileServer(fs)

	if !fs.Exists("/", "/index.html") {
		s.logger.Warn().Msg("Unable to locate Web App at `" + s.cfg.WebAppSrc + "`. " +
			"It may not be built or be configured incorrectly.")
		fs = nil
		fileserver = nil
	}
	indexFilePath := path.Join(s.cfg.WebAppSrc, "index.html")

	staticFS, err := static.EmbedFolder(staticFS, ".")
	if err != nil {
		panic(err)
	}
	staticFileSserver := http.FileServer(staticFS)

	webdavPath := s.cfg.WebDAV.Path
	if !strings.HasSuffix(webdavPath, "/'") {
		webdavPath += "/"
	}

	publinkPath := s.cfg.PublinkPath
	if !strings.HasSuffix(publinkPath, "/'") {
		publinkPath += "/"
	}

	mime.AddExtensionType(".webmanifest", "application/manifest+json")
	staticFileHandler := func(c *gin.Context) {
		path := c.Request.URL.Path
		if strings.HasPrefix(path, "/__static") && staticFS.Exists("/", c.Request.URL.Path) {
			staticFileSserver.ServeHTTP(c.Writer, c.Request)
			return
		}

		if fs != nil && c.Request.Method == "GET" &&
			!strings.HasPrefix(path, "/api") &&
			!strings.HasPrefix(path, webdavPath) &&
			!strings.HasPrefix(path, publinkPath) {
			c.Writer.Header().Set("Cross-Origin-Embedder-Policy", "credentialless")
			c.Writer.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
			if fs.Exists("/", c.Request.URL.Path) {
				if c.Request.URL.Path == "/" {
					c.Writer.Header().Set("Cache-Control", "no-store")
				} else {
					for _, r := range immutableResources {
						if r.MatchString(c.Request.URL.Path) {
							c.Writer.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
						}
					}
				}
				fileserver.ServeHTTP(c.Writer, c.Request)
			} else {
				c.Writer.Header().Set("Cache-Control", "no-store")
				http.ServeFile(c.Writer, c.Request, indexFilePath)
			}
		} else {
			c.JSON(http.StatusNotFound, gin.H{
				"status": 404,
				"code":   "route_not_found",
				"msg":    "Route Not Found",
			})
		}
	}
	s.engine.NoRoute(staticFileHandler)
}
