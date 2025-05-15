package command

import (
	"github.com/shroff/phylum/server/internal/command/serve"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

var defaultConfig = Config{
	Debug: false,
	DB: db.Config{
		Host:      "localhost",
		Port:      5432,
		DBName:    "phylum",
		User:      "phylum",
		Password:  "phylum",
		NoMigrate: false,
		Trace:     false,
	},
	Storage: storage.Config{
		Location: "storage",
	},
	Server: serve.Config{
		Host:        "",
		Port:        2448,
		WebAppSrc:   "web",
		PublinkPath: "/publink",
		WebDAVPath:  "/webdav",
		CORS: serve.CORSConfig{
			Enabled: false,
			Origins: []string{"*"},
		},
	},
}

type Config struct {
	Debug   bool           `koanf:"debug"`
	DB      db.Config      `koanf:"db"`
	Storage storage.Config `koanf:"storage"`
	Server  serve.Config   `koanf:"server"`
}
