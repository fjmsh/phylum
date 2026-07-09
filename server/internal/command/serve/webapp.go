package serve

import (
	"net/http"
	"path"
	"strings"

	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func setupWebApp(engine *gin.Engine, logger *zerolog.Logger, webAppSrcDir string) {
	fs := static.LocalFile(webAppSrcDir, false)
	fileserver := http.FileServer(fs)

	if !fs.Exists("/", "/index.html") {
		logger.Warn().Msg("Unable to locate Web App at `" + webAppSrcDir + "`. " +
			"It may not be built or be configured incorrectly.")
		fs = nil
		fileserver = nil
	}
	indexFilePath := path.Join(webAppSrcDir, "index.html")

	staticFS, err := static.EmbedFolder(staticFS, ".")
	if err != nil {
		panic(err)
	}
	staticFileSserver := http.FileServer(staticFS)

	webdavPath := Cfg.WebDAV.Path
	if !strings.HasSuffix(webdavPath, "/'") {
		webdavPath += "/"
	}

	publinkPath := Cfg.PublinkPath
	if !strings.HasSuffix(webdavPath, "/'") {
		publinkPath += "/"
	}

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
				fileserver.ServeHTTP(c.Writer, c.Request)
			} else {
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
	engine.NoRoute(staticFileHandler)
}
