package server

type Config struct {
	Host        string `koanf:"host"`
	Port        int    `koanf:"port"`
	WebAppSrc   string `koanf:"web_app_src"`
	PublinkPath string `koanf:"publink_path"`
	WebDAV      struct {
		Enabled bool   `koanf:"enabled"`
		Path    string `koanf:"path"`
	} `koanf:"webdav"`
	CORS struct {
		Enabled bool     `koanf:"enabled"`
		Origins []string `koanf:"origins"`
	} `koanf:"cors"`
	Debug   bool `koanf:"debug"`
	LogBody bool `koanf:"log_body"`
}
