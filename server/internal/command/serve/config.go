package serve

type Config struct {
	Host        string     `koanf:"host"`
	Port        int        `koanf:"port"`
	WebAppSrc   string     `koanf:"webappsrc"`
	PublinkPath string     `koanf:"publinkpath"`
	WebDAVPath  string     `koanf:"webdavpath"`
	CORS        CORSConfig `koanf:"cors"`
	Debug       bool       `koanf:"debug"`
	LogBody     bool       `koanf:"logbody"`
}

type CORSConfig struct {
	Enabled bool     `koanf:"enabled"`
	Origins []string `koanf:"origins"`
}
