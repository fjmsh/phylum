package command

import "github.com/shroff/phylum/server/internal/core/db"

var defaultConfig = Config{
	DB: db.Config{
		Host:     "localhost",
		Port:     5432,
		DBName:   "phylum",
		User:     "phylum",
		Password: "phylum",
	},
	Storage: StorageConfig{
		Location: "storage",
	},
	Server: ServerConfig{
		Host:        "",
		Port:        2448,
		WebAppSrc:   "web",
		PublinkPath: "/publink",
		WebDAVPath:  "/webdav",
		CORS: CORSConfig{
			Enabled: false,
			Orifins: []string{"*"},
		},
	},
}

type Config struct {
	Debug   bool          `koanf:"debug"`
	DB      db.Config     `koanf:"db"`
	Storage StorageConfig `koanf:"storage"`
	Server  ServerConfig  `koanf:"server"`
}

type ServerConfig struct {
	Host        string     `koanf:"host"`
	Port        int        `koanf:"port"`
	WebAppSrc   string     `koanf:"web_app_src"`
	PublinkPath string     `koanf:"publink_path"`
	WebDAVPath  string     `koanf:"webdav_path"`
	CORS        CORSConfig `koanf:"cors"`
}

type CORSConfig struct {
	Enabled bool     `koanf:"enabled"`
	Orifins []string `koanf:"origins"`
}

type StorageConfig struct {
	Location string `koanf:"location"`
}
