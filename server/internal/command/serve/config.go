package serve

type Config struct {
	Host        string       `koanf:"host"`
	Port        int          `koanf:"port"`
	PublinkPath string       `koanf:"publinkpath"`
	WebDAV      WebDAVConfig `koanf:"webdav"`
	CORS        CORSConfig   `koanf:"cors"`
	Debug       bool         `koanf:"debug"`
	LogBody     bool         `koanf:"logbody"`
}

type WebDAVConfig struct {
	Enabled bool   `koanf:"enabled"`
	Path    string `koanf:"path"`
}

type CORSConfig struct {
	Enabled bool     `koanf:"enabled"`
	Origins []string `koanf:"origins"`
}
