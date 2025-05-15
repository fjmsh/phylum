package command

var defaultConfig = Config{
	DB: DBConfig{
		Host:     "localhost",
		Port:     5432,
		Username: "phylum",
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
	DB      DBConfig      `koanf:"db"`
	Storage StorageConfig `koanf:"storage"`
	Server  ServerConfig  `koanf:"server"`
}

type DBConfig struct {
	Host          string `koanf:"host"`
	Port          int    `koanf:"port"`
	Username      string `koanf:"username"`
	Password      string `koanf:"password"`
	SkipMigration bool   `koanf:"skip-migration"`
	TraceQueries  bool   `koanf:"trace-queries"`
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
